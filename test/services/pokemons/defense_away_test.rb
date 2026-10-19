# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DefenseAwayTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @user = users(:user_one)
      @rival = users(:user_two)
      @profile = @user.trainer_profile
      @profile.update!(last_studio_visit_at: 1.day.ago)
    end

    test 'first visit reports nothing and stamps the clock' do
      @profile.update!(last_studio_visit_at: nil)

      report = DefenseAway.claim!(@user)

      assert_equal [0, 0], [report.wins, report.losses]
      assert_not_nil @profile.reload.last_studio_visit_at
    end

    test 'counts defense wins and losses since the last studio visit' do
      create_pokemon_battle(attacker: @rival, defender: @user, winner: @user, created_at: 2.hours.ago)
      create_pokemon_battle(attacker: @rival, defender: @user, winner: @rival, created_at: 1.hour.ago)
      create_pokemon_battle(attacker: @rival, defender: @user, winner: @rival, created_at: 2.days.ago)
      create_pokemon_battle(attacker: @user, defender: @rival, winner: @rival, created_at: 30.minutes.ago)

      report = DefenseAway.claim!(@user)

      assert_equal [1, 1], [report.wins, report.losses]
      assert_predicate report, :any?
    end

    test 'a second claim in a row is empty' do
      create_pokemon_battle(attacker: @rival, defender: @user, winner: @rival, created_at: 1.hour.ago)
      DefenseAway.claim!(@user)

      report = DefenseAway.claim!(@user.reload)

      assert_equal [0, 0], [report.wins, report.losses]
    end
  end
end
