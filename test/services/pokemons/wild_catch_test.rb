# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class WildCatchTest < ActiveSupport::TestCase
    include WildCatchServiceHelpers

    def setup
      @user = users(:user_one)
      @pokemon = pokemons(:two)
      @session = {}
    end

    test 'a page roll writes no encounter and leaves a signed-in session untouched' do
      assert_no_difference('PokemonEncounter.count') { assert roll(user: @user) }
      assert_empty @session
    end

    test 'showing the pop-up records an open encounter for the user' do
      encounter = nil

      assert_difference('PokemonEncounter.count') { encounter = show(user: @user) }
      assert_equal [@user.id, @pokemon.id, 'open'], [encounter.user_id, encounter.pokemon_id, encounter.status]
    end

    test 'showing the pop-up starts the gap and writes no guest keys' do
      show(user: @user)

      assert_equal [:pokemon_catch_last_seen], @session.keys
    end

    test 'a missing or forged ticket shows nothing' do
      assert_no_difference('PokemonEncounter.count') do
        assert_nil show(user: @user, ticket: nil)
        assert_nil show(user: @user, ticket: 'forged')
      end
    end

    test "another user's or an expired ticket shows nothing" do
      ticket = roll(user: @user)

      assert_nil show(user: users(:user_two), ticket:)
      travel(WildCatch::TICKET_TTL + 1.minute) { assert_nil show(user: @user, ticket:) }
    end

    test 'a signed-in user who ignores a pop-up gets no new one for 8 hours' do
      show(user: @user)

      travel(Balance::ENCOUNTER_DELAY - 1.minute) { assert_nil roll(user: @user) }
      travel(Balance::ENCOUNTER_DELAY + 1.minute) { assert roll(user: @user) }
    end

    test 'one ticket shows one pop-up' do
      ticket = roll(user: @user)
      show(user: @user, ticket:)

      assert_no_difference('PokemonEncounter.count') { assert_nil show(user: @user, ticket:) }
    end

    test 'a lost session stamp still blocks a second pop-up within the delay' do
      show(user: @user)
      @session.clear

      assert_no_difference('PokemonEncounter.count') { assert_nil show(user: @user) }
    end

    test 'the gap survives the JSON session cookie' do
      @session[:pokemon_catch_last_seen] = 1.hour.ago.iso8601

      assert_nil roll(user: @user)
    end

    test 'a recent catch means no roll' do
      @user.trainer_profile.update!(last_catch_at: 1.hour.ago)

      assert_nil roll(user: @user)
    end

    test 'the chance is 2%' do
      assert_nil roll(user: @user, dice: WildCatch::ENCOUNTER_CHANCE + 0.01)
      assert roll(user: @user, dice: WildCatch::ENCOUNTER_CHANCE - 0.001)
    end
  end
end
