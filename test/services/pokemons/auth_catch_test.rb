# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class AuthCatchTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_two)
      @pokemon = pokemons(:four)
      @encounter = PokemonEncounter.roll!(pokemon: @pokemon, guest_token: 'guest-token')
    end

    test 'guest_encounter ignores an encounter that belongs to another guest or a user' do
      assert_nil Pokemons::AuthCatch.guest_encounter(guest_session.merge(pokemon_guest_token: 'other-guest'))

      user_encounter = PokemonEncounter.roll!(pokemon: @pokemon, user: users(:user_one))

      assert_nil Pokemons::AuthCatch.guest_encounter(guest_session.merge(pokemon_encounter_id: user_encounter.id))
    end

    test 'transfer_guest_catch! traps the encounter pokemon and closes the encounter' do
      assert transfer(guest_session)
      assert UserPokemon.exists?(user_id: @user.id, pokemon_id: @pokemon.id)
      assert_predicate @encounter.reload, :caught?
    end

    test 'transfer_guest_catch! clears the guest catch from the session' do
      session = guest_session
      transfer(session)

      assert_empty session.slice(:pokemon_encounter_id, :pokemon_guest_caught)
    end

    test 'transfer_guest_catch! needs the guest to have clicked the encounter' do
      assert_not transfer(guest_session.except(:pokemon_guest_caught))
      assert_predicate @encounter.reload, :open?
    end

    test 'transfer_guest_catch! claims a guest encounter only once' do
      session = guest_session
      copy = session.dup

      assert transfer(session)
      assert_not transfer(copy, user: users(:user_one))
    end

    test 'transfer_guest_catch! rejects an expired encounter' do
      travel PokemonEncounter::EXPIRES_IN + 1.minute do
        assert_not transfer(guest_session)
      end
    end

    test 'assign_on_signup! delegates to SignupCatchAssigner' do
      session = {}
      called = false
      stub = Object.new
      stub.define_singleton_method(:perform) do
        called = true
        'unconfirmed'
      end

      Pokemons::SignupCatchAssigner.stub(:new, lambda { |user, sess|
        assert_equal @user, user
        assert_equal session, sess
        stub
      }) do
        assert_equal 'unconfirmed', Pokemons::AuthCatch.assign_on_signup!(user: @user, session: session)
      end

      assert called
    end

    test 'after_omniauth! with guest catch returns with_pokemon' do
      assert_equal :with_pokemon, Pokemons::AuthCatch.after_omniauth!(user: @user, session: guest_session)
      assert UserPokemon.exists?(user_id: @user.id, pokemon_id: @pokemon.id)
    end

    test 'after_omniauth! without guest catch grants starter when collection empty' do
      @user.user_pokemons.destroy_all
      session = {}

      assert_equal :without_pokemon, Pokemons::AuthCatch.after_omniauth!(user: @user, session: session)
      assert_predicate @user.pokemons.reload, :any?
    end

    test 'after_omniauth! with an expired guest catch grants a starter instead' do
      @user.user_pokemons.destroy_all

      travel PokemonEncounter::EXPIRES_IN + 1.minute do
        assert_equal :without_pokemon, Pokemons::AuthCatch.after_omniauth!(user: @user, session: guest_session)
      end
      assert_predicate @encounter.reload, :open?
    end

    private

    def transfer(session, user: @user)
      Pokemons::AuthCatch.transfer_guest_catch!(user:, session:)
    end

    def guest_session
      { pokemon_guest_caught: true, pokemon_encounter_id: @encounter.id, pokemon_guest_token: 'guest-token' }
    end
  end
end
