# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class CloseSeasonJobTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    test 'closes a season whose last day has passed' do
      season = pokemon_seasons(:current)
      _starts_on, ends_on = Seasons::Calendar.period_covering(Date.new(2026, 8, 1))
      season.update!(ends_on:)
      create_pokemon_battle(attacker: users(:user_one), defender: users(:user_two))

      travel_to (ends_on + 1.day).in_time_zone do
        CloseSeasonJob.perform_now
      end

      assert_predicate season.reload, :closed?
      assert_predicate PokemonSeason.current, :present?
    end
  end
end
