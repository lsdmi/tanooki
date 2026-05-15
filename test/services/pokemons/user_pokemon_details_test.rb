# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class UserPokemonDetailsTest < ActiveSupport::TestCase
    def setup
      @user_pokemon = user_pokemons(:one)
      @pokemon = pokemons(:one)
      @service = UserPokemonDetails.new(@user_pokemon.id)
    end

    test 'initializes with pokemon_id' do
      assert_equal @user_pokemon.id, @service.instance_variable_get(:@pokemon_id)
    end

    test 'call returns successful OperationOutcome' do
      result = @service.call

      assert_instance_of Outcomes::OperationOutcome, result
      assert_predicate result, :success?
    end

    test 'call data includes selected user pokemon and descendant' do
      result = @service.call

      assert_equal @user_pokemon, result.data[:selected_pokemon]
      assert_equal @pokemon.descendant, result.data[:descendant]
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

    test 'descendant returns pokemon descendant when different from pokemon' do
      descendant = @service.send(:descendant)

      assert_not_nil descendant
      assert_equal 2, descendant.id
      assert_equal 'Second', descendant.name
    end

    test 'descendant memoizes the result' do
      first_call = @service.send(:descendant)
      second_call = @service.send(:descendant)

      assert_equal first_call, second_call
      assert_same first_call, second_call
    end

    test 'call with non-existent pokemon_id handles gracefully' do
      service = UserPokemonDetails.new(99_999)

      assert_raises(ActiveRecord::RecordNotFound) do
        service.call
      end
    end

    test 'data structure contains all expected keys' do
      result = @service.call

      assert_includes result.data.keys, :selected_pokemon
      assert_includes result.data.keys, :descendant
      assert_equal 2, result.data.keys.length
    end

    test 'descendant logic works with pokemon that has different descendant' do
      pokemons(:one)
      user_pokemon_with_descendant = user_pokemons(:one)
      service_with_descendant = UserPokemonDetails.new(user_pokemon_with_descendant.id)

      descendant = service_with_descendant.send(:descendant)

      assert_not_nil descendant
      assert_equal 2, descendant.id
      assert_equal 'Second', descendant.name
    end
  end
end
