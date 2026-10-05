# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Battle
    class RatingUpdaterTest < ActiveSupport::TestCase
      def setup
        @attacker = trainer_profiles(:user_one)
        @defender = trainer_profiles(:user_two)
        @service = RatingUpdater.new(winner: @attacker, loser: @defender)
      end

      test 'winner and loser ratings are updated correctly' do
        @service.call

        # Same rank (fixtures default rating 50) -> update_equal_rank: +2 / -2
        assert_equal [52, 48], [@attacker.reload.rating, @defender.reload.rating]
      end

      test 'rating never drops below 0' do
        @attacker.update!(rating: 1)
        @defender.update!(rating: 1)
        RatingUpdater.new(winner: @defender, loser: @attacker).call

        assert_equal 0, @attacker.reload.rating
      end

      test 'rating never rises above 100' do
        @attacker.update!(rating: 99)
        @defender.update!(rating: 99)
        @service.call

        assert_equal 100, @attacker.reload.rating
      end

      test 'returns the change each side actually got, by user id' do
        @attacker.update!(rating: 99)
        @defender.update!(rating: 99)

        assert_equal({ @attacker.user_id => 1, @defender.user_id => -2 }, @service.call)
      end
    end
  end
end
