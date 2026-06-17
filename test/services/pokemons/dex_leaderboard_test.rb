# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DexLeaderboardTest < ActiveSupport::TestCase
    setup do
      @leaderboard = DexLeaderboard.new
      @first = users(:user_one)
      @second = users(:user_two)
      @third = User.find(102)

      UserPokemon.create!(
        pokemon_id: pokemons(:one).id,
        user: @third,
        current_level: 1,
        battle_experience: 1,
        character: 'Таланистий'
      )

      @first.update!(battle_win_rate: 80)
      @second.update!(battle_win_rate: 60)
      @third.update!(battle_win_rate: 40)
    end

    test 'ranks three or more users by battle win rate' do
      assert_equal 1, @leaderboard.rank_for(@first)
      assert_equal 2, @leaderboard.rank_for(@second)
      assert_equal 3, @leaderboard.rank_for(@third)
    end

    test 'tie-breaks equal win rates by user id' do
      @first.update!(battle_win_rate: 50)
      @second.update!(battle_win_rate: 50)

      assert_equal 1, @leaderboard.rank_for(@first)
      assert_equal 2, @leaderboard.rank_for(@second)
    end

    test 'returns nil for users not on the leaderboard' do
      assert_nil @leaderboard.rank_for(User.find(101))
    end

    test 'rank_for uses a bounded number of queries' do
      assert_queries_count(2) { @leaderboard.rank_for(@first) }
    end

    test 'size returns distinct leaderboard count' do
      assert_equal 3, @leaderboard.size
    end
  end
end
