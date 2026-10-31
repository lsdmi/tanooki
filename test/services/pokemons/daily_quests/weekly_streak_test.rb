# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module DailyQuests
    class WeeklyStreakTest < ActiveSupport::TestCase
      setup do
        Pool.reload!
        Items::Catalog.reload!
        @user = users(:user_one)
        TrainerDailyQuest.where(user: @user).delete_all
        CandyTransaction.where(user: @user).delete_all
        @user.trainer_profile.update!(candies: 0, weekly_streak_claimed_on: nil, item_effects: {})
        travel_to Time.zone.local(2026, 10, 23, 12) # Friday
      end

      teardown { travel_back }

      test 'counts distinct completed days and ignores incomplete rows' do
        seed_completed_day(Date.new(2026, 10, 19)) # Mon
        seed_completed_day(Date.new(2026, 10, 21)) # Wed
        seed_open_day(Date.new(2026, 10, 22)) # Thu incomplete

        status = WeeklyStreak.status(@user)

        assert_equal 2, status.days
        assert_equal 5, status.required
        assert_not status.claimed?
      end

      test 'status week_start is Monday of the current week' do
        assert_equal Date.new(2026, 10, 19), WeeklyStreak.status(@user).week_start
      end

      test 'skipped days do not clear earlier progress in the same week' do
        seed_completed_day(Date.new(2026, 10, 19))
        seed_completed_day(Date.new(2026, 10, 20))
        # Tue gap is fine — Wed still counts toward 5/7
        seed_completed_day(Date.new(2026, 10, 22))

        assert_equal 3, WeeklyStreak.status(@user).days
      end

      test 'fifth completed day grants streak candies once' do
        4.times { |i| seed_completed_day(Date.new(2026, 10, 19) + i) }

        Items::Catalog.stub(:quest_reward_key, 'protein') do
          seed_today_quest!
          Progress.call(@user, event: :training)
          Progress.call(@user, event: :training)
        end

        profile = @user.trainer_profile.reload

        assert_equal Date.new(2026, 10, 19), profile.weekly_streak_claimed_on
        assert_equal 1, CandyTransaction.where(user: @user, reason: 'weekly_streak').count
        assert_equal(
          Items::Catalog.quest_candy_reward + Pool.weekly_streak_candy_reward,
          profile.candies
        )
      end

      test 'completing another quest the same day does not pay the streak again' do
        4.times { |i| seed_completed_day(Date.new(2026, 10, 19) + i) }

        Items::Catalog.stub(:quest_reward_key, 'protein') do
          seed_today_quest!
          Progress.call(@user, event: :training)
          Progress.call(@user, event: :training)

          other = TrainerDailyQuest.find_by!(user: @user, quest_on: Time.zone.today, quest_key: 'win_battle')
          other.update!(progress: 0, completed_at: nil)
          Progress.call(@user, event: :battle_win)
        end

        assert_equal 1, CandyTransaction.where(user: @user, reason: 'weekly_streak').count
      end

      test 'previous week claim does not block the new week' do
        @user.trainer_profile.update!(weekly_streak_claimed_on: Date.new(2026, 10, 12))
        4.times { |i| seed_completed_day(Date.new(2026, 10, 19) + i) }

        Items::Catalog.stub(:quest_reward_key, 'protein') do
          seed_today_quest!
          Progress.call(@user, event: :training)
          Progress.call(@user, event: :training)
        end

        assert_equal Date.new(2026, 10, 19), @user.trainer_profile.reload.weekly_streak_claimed_on
        assert_equal 1, CandyTransaction.where(user: @user, reason: 'weekly_streak').count
      end

      private

      def seed_completed_day(on)
        TrainerDailyQuest.create!(
          user: @user, quest_on: on, quest_key: 'train_pokemon',
          progress: 1, target: 1, completed_at: on.in_time_zone.midday
        )
      end

      def seed_open_day(on)
        TrainerDailyQuest.create!(
          user: @user, quest_on: on, quest_key: 'train_pokemon',
          progress: 0, target: 1
        )
      end

      def seed_today_quest!
        %w[win_battle read_chapters train_pokemon].each do |key|
          definition = Pool.fetch(key)
          TrainerDailyQuest.create!(
            user: @user, quest_on: Time.zone.today, quest_key: key,
            progress: 0, target: definition.fetch('target').to_i
          )
        end
      end
    end
  end
end
