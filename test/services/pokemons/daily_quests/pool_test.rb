# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module DailyQuests
    class PoolTest < ActiveSupport::TestCase
      setup { Pool.reload! }

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

      test 'matches chapter reads only when the genre filter is satisfied' do
        fantasy = Pool.fetch('read_fantasy_chapters')

        assert Pool.matches?(fantasy, event: :chapter_read, genre_slugs: %w[fantasy action])
        assert_not Pool.matches?(fantasy, event: :chapter_read, genre_slugs: %w[romance])
      end
    end
  end
end
