# frozen_string_literal: true

module Pokemons
  module DailyQuests
    # Creates today's three quest rows once; returns them ordered for Studio.
    class EnsureToday
      def self.call(user) = new(user).call

      def initialize(user, profile: nil)
        @user = user
        @profile = profile
      end

      def call
        profile.with_lock { ensure_rows! }
      end

      # Caller already holds the trainer_profile row lock.
      def ensure_rows!
        on = Time.zone.today
        existing = TrainerDailyQuest.where(user_id: @user.id, quest_on: on).order(:id).to_a
        return existing if existing.size >= Pool.pick

        create_missing!(on, existing)
        TrainerDailyQuest.where(user_id: @user.id, quest_on: on).order(:id).to_a
      end

      private

      def create_missing!(on, existing)
        missing = Pool.pick_keys(user_id: @user.id, on:) - existing.map(&:quest_key)
        missing.each do |key|
          target = Pool.fetch(key).fetch('target').to_i
          TrainerDailyQuest.create!(
            user_id: @user.id, quest_on: on, quest_key: key, progress: 0, target:
          )
        end
      end

      def profile
        @profile ||= @user.trainer_profile
      end
    end
  end
end
