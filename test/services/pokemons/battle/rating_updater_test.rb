# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Battle
    class RatingUpdaterTest < ActiveSupport::TestCase
      def setup
        @winner = trainer_profiles(:user_one)
        @loser = trainer_profiles(:user_two)
      end

      test 'two newcomers move apart symmetrically and return the rounded change' do
        deltas = RatingUpdater.new(winner: @winner, loser: @loser).call

        assert_equal({ @winner.user_id => 162, @loser.user_id => -162 }, deltas)
        assert_in_delta 1662.2, @winner.reload.glicko_rating, 0.1
        assert_in_delta 1337.8, @loser.reload.glicko_rating, 0.1
      end

      test 'a battle makes both sides surer and moves the floor with them' do
        RatingUpdater.new(winner: @winner, loser: @loser).call

        assert_in_delta 290.2, @winner.reload.glicko_deviation, 0.1
        assert_in_delta @winner.glicko.floor, @winner.glicko_floor, 0.000001
      end

      test 'beating a much weaker trainer earns little' do
        @winner.update!(glicko_rating: 1900, glicko_deviation: 60, last_battle_at: 1.hour.ago)
        @loser.update!(glicko_rating: 1400, glicko_deviation: 60, last_battle_at: 1.hour.ago)

        deltas = RatingUpdater.new(winner: @winner, loser: @loser).call

        assert_equal [1, -1], deltas.values_at(@winner.user_id, @loser.user_id)
      end

      test 'rates both sides from their ratings before the battle, grown by their own idle time' do
        at = Time.zone.parse('2026-10-08 12:00')
        @winner.update!(glicko_rating: 1600, glicko_deviation: 60, last_battle_at: at - 1.hour)
        @loser.update!(glicko_rating: 1600, glicko_deviation: 60, last_battle_at: at - 365.days)
        winner_before = @winner.glicko
        loser_before = @loser.glicko

        RatingUpdater.new(winner: @winner, loser: @loser, at:).call

        assert_equal Ratings::Glicko2.rate(winner_before, [[loser_before.idle(365), 1]], periods: 1.0 / 24),
                     @winner.reload.glicko
        assert_operator 1600 - @loser.reload.glicko_rating, :>, 3 * (@winner.glicko_rating - 1600)
      end
    end
  end
end
