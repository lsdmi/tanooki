# frozen_string_literal: true

module Pokemons
  module DailyQuests
    # Bumps matching incomplete daily quests for an action that just succeeded.
    class Progress
      def self.call(user, event:, types: [], genre_slugs: [])
        new(user).call(event:, types:, genre_slugs:)
      end

      def initialize(user)
        @user = user
      end

      def call(event:, types: [], genre_slugs: [])
        return if @user.nil?

        TrainerProfile.transaction do
          profile = TrainerProfile.lock.find_by(user_id: @user.id)
          return if profile.nil?

          EnsureToday.new(@user, profile:).ensure_rows!.each do |row|
            bump!(row, event:, types:, genre_slugs:)
          end
        end
      end

      private

      def bump!(row, event:, types:, genre_slugs:)
        return if row.completed?

        definition = Pool.fetch(row.quest_key)
        return unless Pool.matches?(definition, event:, types:, genre_slugs:)

        row.progress = [row.progress + 1, row.target].min
        row.completed_at = Time.current if row.progress >= row.target
        row.save!
      end
    end
  end
end
