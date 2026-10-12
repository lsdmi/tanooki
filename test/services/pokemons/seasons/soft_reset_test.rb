# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Seasons
    class SoftResetTest < ActiveSupport::TestCase
      test 'pulls the rating halfway to 1500 and raises a settled deviation to 150' do
        before = Ratings::Glicko2::Rating.new(rating: 1900, deviation: 80, volatility: 0.06)

        after = SoftReset.apply(before)

        assert_in_delta 1700, after.rating
        assert_in_delta 150, after.deviation
        assert_in_delta 0.06, after.volatility
      end

      test 'keeps a wider deviation' do
        before = Ratings::Glicko2::Rating.new(rating: 1400, deviation: 220, volatility: 0.06)

        after = SoftReset.apply(before)

        assert_in_delta 1450, after.rating
        assert_in_delta 220, after.deviation
      end
    end
  end
end
