# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Seasons
    class CloseTest < ActiveSupport::TestCase
      include PokemonBattleHelpers

      setup do
        @season = pokemon_seasons(:current)
        @first = users(:user_one)
        @second = users(:user_two)
        @first.trainer_profile.update!(glicko_rating: 1800, glicko_deviation: 100)
        @second.trainer_profile.update!(glicko_rating: 1600, glicko_deviation: 90)
        create_pokemon_battle(attacker: @first, defender: @second, winner: @first)
        @starts_on, @ends_on = Calendar.period_covering(Date.new(2026, 8, 1))
      end

      test 'does nothing while the season still has days left' do
        assert_equal :already, Close.call
        assert_predicate @season.reload, :open?
      end

      test 'writes a standing for each fighter before the reset' do
        @season.update!(starts_on: @starts_on, ends_on: @ends_on)

        Close.call(at: (@ends_on + 1.day).in_time_zone)
        result = SeasonResult.find_by!(pokemon_season: @season, user: @first)

        assert_equal [1, 1], [result.place, result.wins]
      end

      test 'soft-resets ratings halfway to 1500 with a deviation floor of 150' do
        @season.update!(starts_on: @starts_on, ends_on: @ends_on)

        Close.call(at: (@ends_on + 1.day).in_time_zone)
        profile = @first.trainer_profile.reload

        assert_in_delta 1650, profile.glicko_rating
        assert_in_delta 150, profile.glicko_deviation
      end

      test 'closes the season and opens the next two-month block' do
        @season.update!(starts_on: @starts_on, ends_on: @ends_on)

        Close.call(at: (@ends_on + 1.day).in_time_zone)
        next_season = PokemonSeason.current

        assert_predicate @season.reload, :closed?
        assert_equal [@season.number + 1, @ends_on + 1.day], [next_season.number, next_season.starts_on]
      end

      test 'a second call after close is a no-op for the new season' do
        @season.update!(ends_on: @ends_on)
        Close.call(at: (@ends_on + 1.day).in_time_zone)

        assert_equal :already, Close.call(at: (@ends_on + 1.day).in_time_zone)
      end
    end
  end
end
