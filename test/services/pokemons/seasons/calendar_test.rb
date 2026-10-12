# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Seasons
    class CalendarTest < ActiveSupport::TestCase
      test 'two-month blocks cover the year without gaps' do
        assert_equal [Date.new(2026, 9, 1), Date.new(2026, 10, 31)], Calendar.period_covering(Date.new(2026, 10, 12))
        assert_equal [Date.new(2026, 11, 1), Date.new(2026, 12, 31)], Calendar.period_covering(Date.new(2026, 11, 1))
        assert_equal [Date.new(2026, 1, 1), Date.new(2026, 2, 28)], Calendar.period_covering(Date.new(2026, 2, 1))
      end

      test 'the next block starts the day after a season ends' do
        assert_equal [Date.new(2026, 11, 1), Date.new(2026, 12, 31)], Calendar.period_after(Date.new(2026, 10, 31))
      end
    end
  end
end
