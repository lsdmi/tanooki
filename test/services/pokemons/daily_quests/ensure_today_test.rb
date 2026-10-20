# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module DailyQuests
    class EnsureTodayTest < ActiveSupport::TestCase
      setup do
        Pool.reload!
        @user = users(:user_one)
        TrainerDailyQuest.where(user: @user).delete_all
      end

      test 'creates three quests for today and is idempotent' do
        travel_to Time.zone.local(2026, 10, 19, 12) do
          first = EnsureToday.call(@user)

          assert_equal 3, first.size
          assert_equal first.map(&:quest_key), EnsureToday.call(@user).map(&:quest_key)
          assert_equal 3, TrainerDailyQuest.where(user: @user, quest_on: Date.new(2026, 10, 19)).count
        end
      end

      test 'a new Kiev day gets a fresh set' do
        travel_to Time.zone.local(2026, 10, 19, 23) do
          EnsureToday.call(@user)
        end

        travel_to Time.zone.local(2026, 10, 20, 1) do
          keys = EnsureToday.call(@user).map(&:quest_key)

          assert_equal 3, keys.size
          assert_equal 6, TrainerDailyQuest.where(user: @user).count
        end
      end
    end
  end
end
