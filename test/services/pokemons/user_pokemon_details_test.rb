# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class UserPokemonDetailsTest < ActiveSupport::TestCase
    def setup
      @user_pokemon = user_pokemons(:one)
      @pokemon = pokemons(:one)
      @service = UserPokemonDetails.new(@user_pokemon.user, @user_pokemon.id)
    end

    test 'initializes with pokemon_id' do
      assert_equal @user_pokemon.id, @service.instance_variable_get(:@pokemon_id)
    end

    test 'call returns successful OperationOutcome' do
      result = @service.call

      assert_instance_of Outcomes::OperationOutcome, result
      assert_predicate result, :success?
    end

    test 'call data includes selected user pokemon and the evolution it follows next' do
      result = @service.call

      assert_equal @user_pokemon, result.data[:selected_pokemon]
      assert_equal pokemon_evolutions(:one_to_two), result.data[:evolution]
      assert_equal pokemons(:two), result.data[:evolution].to
    end

    test 'a final form has no evolution' do
      @user_pokemon.update!(pokemon: pokemons(:two))

      assert_nil UserPokemonDetails.new(@user_pokemon.user, @user_pokemon.id).call.data[:evolution]
    end

    test 'selected_pokemon returns user_pokemon with pokemon included' do
      selected = @service.send(:selected_pokemon)

      assert_equal @user_pokemon, selected
      assert_predicate selected.pokemon, :present?
      assert_equal @pokemon, selected.pokemon
    end

    test 'selected_pokemon memoizes the result' do
      first_call = @service.send(:selected_pokemon)
      second_call = @service.send(:selected_pokemon)

      assert_equal first_call, second_call
      assert_same first_call, second_call
    end

    test 'call with non-existent pokemon_id handles gracefully' do
      service = UserPokemonDetails.new(@user_pokemon.user, 99_999)

      assert_raises(ActiveRecord::RecordNotFound) do
        service.call
      end
    end

    test "someone else's pokemon is not found" do
      service = UserPokemonDetails.new(users(:user_two), @user_pokemon.id)

      assert_raises(ActiveRecord::RecordNotFound) { service.call }
    end

    test 'data structure contains all expected keys' do
      result = @service.call

      assert_includes result.data.keys, :selected_pokemon
      assert_includes result.data.keys, :evolution
      assert_equal 2, result.data.keys.length
    end
  end
end
