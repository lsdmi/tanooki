# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class WildCatchGuestTest < ActiveSupport::TestCase
    include WildCatchServiceHelpers

    def setup
      @pokemon = pokemons(:two)
      @session = {}
    end

    test 'a new guest is stamped once' do
      roll(user: nil)
      first_seen = @session[:pokemon_catch_last_seen]
      roll(user: nil)

      assert_equal({ pokemon_catch_last_seen: first_seen }, @session)
    end

    test 'a new guest waits the delay' do
      assert_nil roll(user: nil)
      travel(Balance::ENCOUNTER_DELAY + 1.minute) { assert roll(user: nil) }
    end

    test 'a guest pop-up keeps the encounter id and guest token in the session' do
      @session[:pokemon_catch_last_seen] = 2.years.ago
      @session[:pokemon_guest_caught] = true

      show(user: nil)
      encounter = PokemonEncounter.last

      assert_equal [nil, @pokemon.id], [encounter.user_id, encounter.pokemon_id]
      assert_equal({ pokemon_guest_token: encounter.guest_token, pokemon_encounter_id: encounter.id },
                   @session.slice(:pokemon_guest_token, :pokemon_encounter_id, :pokemon_guest_caught))
    end

    test 'a guest keeps the same token across encounters' do
      @session[:pokemon_catch_last_seen] = 2.years.ago
      @session[:pokemon_guest_token] = 'existing-guest-token'

      show(user: nil)

      assert_equal 'existing-guest-token', PokemonEncounter.last.guest_token
    end

    test 'a guest ticket does nothing for a client without a session' do
      @session[:pokemon_catch_last_seen] = 2.years.ago
      ticket = roll(user: nil)
      @session = {}

      assert_no_difference('PokemonEncounter.count') { assert_nil show(user: nil, ticket:) }
    end

    test 'a guest whose stamp was lost still gets no second pop-up within the delay' do
      @session[:pokemon_catch_last_seen] = 2.years.ago
      show(user: nil)
      @session[:pokemon_catch_last_seen] = 2.years.ago

      assert_no_difference('PokemonEncounter.count') { assert_nil show(user: nil) }
    end
  end
end
