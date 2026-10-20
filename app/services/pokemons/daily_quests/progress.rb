# frozen_string_literal: true

module Pokemons
  module DailyQuests
    # Bumps matching incomplete daily quests for an action that just succeeded.
    class Progress
      def self.call(user, event:, **filters)
        new(user).call(event:, **filters)
      end

      def initialize(user)
        @user = user
      end

      def call(event:, **filters)
        return if @user.nil?

        TrainerProfile.transaction do
          profile = TrainerProfile.lock.find_by(user_id: @user.id)
          return if profile.nil?

          EnsureToday.new(@user, profile:).ensure_rows!.each do |row|
            bump!(row, profile, event:, **filters)
          end
        end
      end

      private

      def bump!(row, profile, event:, **filters)
        return if row.completed?

        definition = Pool.fetch(row.quest_key)
        return unless Pool.matches?(definition, event:, **filters)

        row.progress = [row.progress + 1, row.target].min
        just_completed = row.progress >= row.target
        row.completed_at = Time.current if just_completed
        row.save!
        grant_rewards!(row, profile) if just_completed
      end

      def grant_rewards!(row, profile)
        Candies::Grant.call(
          @user,
          amount: Items::Catalog.quest_candy_reward,
          reason: 'daily_quest',
          source: row,
          profile:
        )
        Items::Grant.call(@user, item_key: Items::Catalog.quest_reward_key)
      end
    end
  end
end
