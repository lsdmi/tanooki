# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module DailyQuests
    class RewardTest < ActiveSupport::TestCase
      setup do
        Pool.reload!
        Items::Catalog.reload!
        @user = users(:user_one)
        TrainerDailyQuest.where(user: @user).delete_all
        TrainerItem.where(user: @user).delete_all
        CandyTransaction.where(user: @user).delete_all
        @user.trainer_profile.update!(candies: 0, item_effects: {})
        travel_to Time.zone.local(2026, 10, 20, 12)
        # Three rows so EnsureToday does not invent extra training quests (e.g. train_twice).
        %w[win_battle read_chapters train_pokemon].each do |key|
          definition = Pool.fetch(key)
          TrainerDailyQuest.create!(
            user: @user, quest_on: Time.zone.today, quest_key: key,
            progress: 0, target: definition.fetch('target').to_i
          )
        end
        @quest = TrainerDailyQuest.find_by!(user: @user, quest_key: 'train_pokemon')
      end

      teardown { travel_back }

      test 'completing a quest grants candies and one item once' do
        Items::Catalog.stub(:quest_reward_key, 'protein') do
          Progress.call(@user, event: :training)
          Progress.call(@user, event: :training)
        end

        assert_predicate @quest.reload, :completed?
        assert_equal Items::Catalog.quest_candy_reward, @user.trainer_profile.reload.candies
        assert_equal 1, TrainerItem.find_by!(user: @user, item_key: 'protein').quantity
      end

      test 'quest candy grant writes one ledger row' do
        Items::Catalog.stub(:quest_reward_key, 'protein') do
          Progress.call(@user, event: :training)
          Progress.call(@user, event: :training)
        end

        assert_equal 1, CandyTransaction.where(user: @user, reason: 'daily_quest').count
      end
    end
  end
end
