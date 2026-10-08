# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Ratings
    class Glicko2Test < ActiveSupport::TestCase
      def rating(value, deviation, volatility = 0.06) = Glicko2::Rating.new(value.to_f, deviation.to_f, volatility)

      test 'matches the worked example in the Glicko-2 paper' do
        games = [[rating(1400, 30), 1], [rating(1550, 100), 0], [rating(1700, 300), 0]]
        rated = Glicko2.rate(rating(1500, 200), games)

        assert_in_delta 1464.06, rated.rating, 0.05
        assert_in_delta 151.52, rated.deviation, 0.05
        assert_in_delta 0.05999, rated.volatility, 0.00001
      end

      test 'an upset moves both sides further than an expected result' do
        settled = rating(1800, 60)
        upset = Glicko2.rate(Glicko2::NEW, [[settled, 1]], periods: 0)
        expected = Glicko2.rate(settled, [[Glicko2::NEW, 1]], periods: 0)

        assert_operator upset.rating - 1500, :>, 300
        assert_operator expected.rating - 1800, :<, 5
      end

      test 'deviation grows while idle and never passes a newcomer' do
        settled = rating(1800, 60)

        assert_in_delta 82.8, settled.idle(30).deviation, 0.1
        assert_in_delta(350.0, settled.idle(10_000).deviation)
        assert_equal settled, settled.idle(0)
      end

      test 'idle time applied at the next battle makes the result count more' do
        settled = rating(1800, 60)
        right_away = Glicko2.rate(settled, [[rating(1800, 60), 0]], periods: 0)
        after_a_year = Glicko2.rate(settled, [[rating(1800, 60), 0]], periods: 365)

        assert_operator 1800 - after_a_year.rating, :>, 3 * (1800 - right_away.rating)
      end

      test 'the floor ranks by rating minus two deviations' do
        assert_in_delta(800.0, Glicko2::NEW.floor)
        assert_in_delta(1680.0, rating(1800, 60).floor)
      end
    end
  end
end
