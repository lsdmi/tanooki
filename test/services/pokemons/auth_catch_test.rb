# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class AuthCatchTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_two)
      @pokemon = pokemons(:two)
    end

    test 'guest_catch_pending? is true when session holds a guest catch' do
      session = { pokemon_guest_caught: true, caught_pokemon_id: @pokemon.id }

      assert Pokemons::AuthCatch.guest_catch_pending?(session)
      assert_not Pokemons::AuthCatch.guest_catch_pending?({})
    end

    test 'transfer_guest_catch! traps the session pokemon' do
      session = { pokemon_guest_caught: true, caught_pokemon_id: @pokemon.id }

      Pokemons::AuthCatch.transfer_guest_catch!(user: @user, session: session)

      assert UserPokemon.exists?(user_id: @user.id, pokemon_id: @pokemon.id)
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
      session = { pokemon_guest_caught: true, caught_pokemon_id: @pokemon.id }

      assert_equal :with_pokemon, Pokemons::AuthCatch.after_omniauth!(user: @user, session: session)
      assert UserPokemon.exists?(user_id: @user.id, pokemon_id: @pokemon.id)
    end

    test 'after_omniauth! without guest catch grants starter when collection empty' do
      @user.user_pokemons.destroy_all
      session = {}

      assert_equal :without_pokemon, Pokemons::AuthCatch.after_omniauth!(user: @user, session: session)
      assert_predicate @user.pokemons.reload, :any?
    end
  end
end
