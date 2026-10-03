# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Battle
    class RatingUpdaterTest < ActiveSupport::TestCase
      def setup
        @attacker = users(:user_one)
        @defender = users(:user_two)

        @service = RatingUpdater.new(
          winner_id: @attacker.id,
          loser_id: @defender.id
        )
      end

      test 'winner and loser battle rates are updated correctly' do
        @service.call

        # Same rank (fixtures default battle_win_rate 50) -> update_equal_rank: +2 / -2
        assert_equal @attacker.battle_win_rate + 2, User.find(@attacker.id).battle_win_rate
        assert_equal @defender.battle_win_rate - 2, User.find(@defender.id).battle_win_rate
      end

      test 'rating never drops below 0' do
        @attacker.update!(battle_win_rate: 1)
        @defender.update!(battle_win_rate: 1)
        RatingUpdater.new(winner_id: @defender.id, loser_id: @attacker.id).call

        assert_equal 0, @attacker.reload.battle_win_rate
      end

      test 'rating never rises above 100' do
        @attacker.update!(battle_win_rate: 99)
        @defender.update!(battle_win_rate: 99)
        @service.call

        assert_equal 100, @attacker.reload.battle_win_rate
      end

      test 'returns the change each side actually got' do
        @attacker.update!(battle_win_rate: 99)
        @defender.update!(battle_win_rate: 99)

        assert_equal({ @attacker.id => 1, @defender.id => -2 }, @service.call)
      end
    end
  end
end
