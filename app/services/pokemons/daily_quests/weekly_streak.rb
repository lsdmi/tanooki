# frozen_string_literal: true

module Pokemons
  module DailyQuests
    # Counts distinct Kiev days this Mon–Sun week with a completed quest (5 needed).
    # Missing a day never clears progress; the candy reward pays once per week.
    class WeeklyStreak
      Status = Data.define(:days, :required, :claimed, :week_start) do
        def claimed? = claimed

        def complete? = days >= required
      end

      def self.status(user, profile: nil) = new(user, profile:).status

      def self.claim_if_eligible!(user, profile:)
        new(user, profile:).claim_if_eligible!
      end

      def initialize(user, profile: nil)
        @user = user
        @profile = profile
      end

      def status
        week_start = self.class.week_start
        Status.new(
          days: completed_days(week_start),
          required: Pool.weekly_streak_days,
          claimed: claimed_for?(week_start),
          week_start:
        )
      end

      # Caller already holds the trainer_profile row lock (from Progress).
      def claim_if_eligible!
        week_start = self.class.week_start
        return if claimed_for?(week_start)
        return if completed_days(week_start) < Pool.weekly_streak_days

        grant_streak!(week_start)
      end

      def self.week_start(on = Time.zone.today)
        on.beginning_of_week
      end

      def self.week_end(on = Time.zone.today)
        on.end_of_week
      end

      private

      def grant_streak!(week_start)
        amount = Pool.weekly_streak_candy_reward
        return if amount <= 0

        Candies::Grant.call(
          @user,
          amount:,
          reason: 'weekly_streak',
          source: nil,
          profile:
        )
        profile.update!(weekly_streak_claimed_on: week_start)
      end

      def completed_days(week_start)
        TrainerDailyQuest
          .where(user_id: @user.id, quest_on: week_start..self.class.week_end(week_start))
          .where.not(completed_at: nil)
          .distinct
          .count(:quest_on)
      end

      def claimed_for?(week_start)
        profile.weekly_streak_claimed_on == week_start
      end

      def profile
        @profile ||= @user.trainer_profile
      end
    end
  end
end
