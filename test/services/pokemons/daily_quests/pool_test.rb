# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module DailyQuests
    class PoolTest < ActiveSupport::TestCase
      setup { Pool.reload! }

      test 'pool has at least ten distinct quest keys' do
        assert_operator Pool.definitions.size, :>=, 10
      end

      test 'pool has no catch quests while wild odds stay low' do
        assert_empty Pool.definitions.keys.grep(/\Acatch/)
      end

      test 'picks a stable set of three keys for a user and day' do
        on = Date.new(2026, 10, 19)
        first = Pool.pick_keys(user_id: 1, on:)
        second = Pool.pick_keys(user_id: 1, on:)

        assert_equal 3, first.size
        assert_equal first, second
        assert_not_equal first, Pool.pick_keys(user_id: 2, on:)
      end

      test 'matches battle wins only when the type filter is satisfied' do
        water = Pool.fetch('win_battle_water')

        assert Pool.matches?(water, event: :battle_win, types: %w[water normal])
        assert_not Pool.matches?(water, event: :battle_win, types: %w[fire])
        assert_not Pool.matches?(water, event: :catch, types: %w[water])
      end

      test 'matches the ranked filter' do
        ranked = Pool.fetch('win_ranked')

        assert Pool.matches?(ranked, event: :battle_win, ranked: true)
        assert_not Pool.matches?(ranked, event: :battle_win, ranked: false)
      end

      test 'side filter still works for future quests' do
        definition = { 'event' => 'battle_win', 'side' => 'defense' }

        assert Pool.matches?(definition, event: :battle_win, side: :defense)
        assert_not Pool.matches?(definition, event: :battle_win, side: :attack)
      end

      test 'matches chapter reads only when the genre filter is satisfied' do
        fantasy = Pool.fetch('read_fantasy_chapters')

        assert Pool.matches?(fantasy, event: :chapter_read, genre_slugs: %w[fantasy action])
        assert_not Pool.matches?(fantasy, event: :chapter_read, genre_slugs: %w[romance])
      end
    end
  end
end
