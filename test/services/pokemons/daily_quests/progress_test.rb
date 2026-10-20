# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module DailyQuests
    class ProgressTest < ActiveSupport::TestCase
      setup do
        Pool.reload!
        @user = users(:user_one)
        TrainerDailyQuest.where(user: @user).delete_all
        travel_to Time.zone.local(2026, 10, 19, 12)
        force_quests(%w[train_pokemon win_battle_water win_ranked read_fantasy_chapters])
      end

      teardown { travel_back }

      test 'training completes the train quest and ignores the others' do
        Progress.call(@user, event: :training)

        assert_equal(
          { 'train_pokemon' => [1, true], 'win_battle_water' => [0, false],
            'read_fantasy_chapters' => [0, false] },
          %w[train_pokemon win_battle_water read_fantasy_chapters]
            .index_with { |key| [quest(key).progress, quest(key).completed?] }
        )
      end

      test 'a water battle win completes the typed win quest' do
        Progress.call(@user, event: :battle_win, types: %w[water])

        assert_predicate quest('win_battle_water'), :completed?
      end

      test 'a fire battle win does not advance the water quest' do
        Progress.call(@user, event: :battle_win, types: %w[fire])

        assert_equal 0, quest('win_battle_water').progress
      end

      test 'a ranked win completes the ranked quest only when ranked' do
        Progress.call(@user, event: :battle_win, ranked: false)

        assert_equal 0, quest('win_ranked').progress

        Progress.call(@user, event: :battle_win, ranked: true)

        assert_predicate quest('win_ranked'), :completed?
      end

      test 'fantasy chapter reads accumulate to the target' do
        Progress.call(@user, event: :chapter_read, genre_slugs: %w[fantasy])
        Progress.call(@user, event: :chapter_read, genre_slugs: %w[fantasy])

        row = quest('read_fantasy_chapters')

        assert_equal 2, row.progress
        assert_predicate row, :completed?
      end

      test 'progress never exceeds the target' do
        3.times { Progress.call(@user, event: :training) }

        assert_equal 1, quest('train_pokemon').progress
      end

      private

      def force_quests(keys)
        on = Time.zone.today
        keys.each do |key|
          definition = Pool.fetch(key)
          TrainerDailyQuest.create!(
            user: @user, quest_on: on, quest_key: key, progress: 0, target: definition.fetch('target').to_i
          )
        end
      end

      def quest(key)
        TrainerDailyQuest.find_by!(user: @user, quest_on: Time.zone.today, quest_key: key)
      end
    end
  end
end
