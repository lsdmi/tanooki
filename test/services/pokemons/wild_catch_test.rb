# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class WildCatchTest < ActiveSupport::TestCase
    def setup
      @user = users(:user_one)
      @pokemon = pokemons(:two)
      @session = {}
    end

    test 'signed-in success returns an open encounter for the user' do
      encounter = nil

      assert_difference('PokemonEncounter.count') { encounter = roll(user: @user) }
      assert_equal [@user.id, @pokemon.id, 'open'], [encounter.user_id, encounter.pokemon_id, encounter.status]
    end

    test 'signed-in success writes no guest keys to the session' do
      roll(user: @user)

      assert_empty @session.slice(:pokemon_encounter_id, :pokemon_guest_token)
    end

    test 'guest success keeps the encounter id and guest token in the session' do
      @session[:pokemon_catch_last_seen] = 2.years.ago

      roll(user: nil)
      encounter = PokemonEncounter.last

      assert_equal [nil, @pokemon.id], [encounter.user_id, encounter.pokemon_id]
      assert_equal encounter.guest_token, @session[:pokemon_guest_token]
      assert_equal encounter.id, @session[:pokemon_encounter_id]
    end

    test 'guest keeps the same token across encounters' do
      @session[:pokemon_guest_token] = 'existing-guest-token'
      @session[:pokemon_catch_last_seen] = 2.years.ago

      roll(user: nil)

      assert_equal 'existing-guest-token', PokemonEncounter.last.guest_token
    end

    test 'signed-in user who ignores a pop-up gets no new one for 8 hours' do
      roll(user: @user)

      assert_no_difference('PokemonEncounter.count') do
        travel(Balance::ENCOUNTER_DELAY - 1.minute) { assert_nil roll(user: @user) }
      end
    end

    test 'signed-in user can get a new pop-up once the gap has passed' do
      roll(user: @user)

      travel(Balance::ENCOUNTER_DELAY + 1.minute) do
        assert_difference('PokemonEncounter.count') { roll(user: @user) }
      end
    end

    test 'signed-in gap survives the JSON session cookie' do
      @session[:pokemon_catch_last_seen] = 1.hour.ago.iso8601

      assert_nil roll(user: @user)
    end

    test 'signed-in page views without a pop-up leave the session untouched' do
      @user.update!(pokemon_last_catch: 1.hour.ago)

      roll(user: @user)

      assert_not @session.key?(:pokemon_catch_last_seen)
    end

    test 'no encounter row when the roll fails' do
      @user.update!(pokemon_last_catch: 1.hour.ago)

      assert_no_difference('PokemonEncounter.count') do
        assert_nil roll(user: @user)
      end
    end

    test 'a long-idle user gets the same 2% chance as everyone else' do
      assert_nil roll(user: @user, dice: WildCatch::ENCOUNTER_CHANCE + 0.01)
      assert_not_nil roll(user: @user, dice: WildCatch::ENCOUNTER_CHANCE)
    end

    test 'a guest gets the 2% chance after the gap' do
      @session[:pokemon_catch_last_seen] = (Balance::ENCOUNTER_DELAY + 1.minute).ago

      assert_nil roll(user: nil, dice: WildCatch::ENCOUNTER_CHANCE + 0.01)
    end

    private

    def roll(user:, dice: 0.0)
      service = WildCatch.new(session: @session, user:)
      service.define_singleton_method(:rand) { |*| dice }

      WildCatchPool.stub(:sample_id, @pokemon.id) { service.call }
    end
  end
end
