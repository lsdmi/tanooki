# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class CollectionUpdaterTest < ActiveSupport::TestCase
    include PokemonEvolutionLineHelpers

    setup do
      make_three_stage_line(stage_two_at: 16, stage_three_at: 32)
      @user_pokemon = user_pokemons(:one)
    end

    test 'catching the base form levels up the stage the user owns and reaches stage 3' do
      @user_pokemon.update!(pokemon: pokemons(:two), current_level: 31)

      trap(pokemons(:one))
      @user_pokemon.reload

      assert_equal pokemons(:three), @user_pokemon.pokemon
      assert_equal 32, @user_pokemon.current_level
    end

    test 'catching a new line adds it at level 1' do
      UserPokemon.where(user_id: @user_pokemon.user_id).delete_all

      assert_difference('UserPokemon.count') { trap(pokemons(:one)) }

      caught = UserPokemon.find_by(user_id: @user_pokemon.user_id)

      assert_equal [1, pokemons(:one).id], [caught.current_level, caught.line_root_id]
      assert_includes UserPokemon::CHARACTERS, caught.character
    end

    test 'catching any form of an owned line levels the owned Pokémon' do
      assert_no_difference('UserPokemon.count') { trap(pokemons(:two)) }
      assert_equal 2, @user_pokemon.reload.current_level
    end

    test 'a user cannot hold two Pokémon of one line' do
      duplicate = UserPokemon.new(user_id: @user_pokemon.user_id, pokemon: pokemons(:two), character: 'brave')

      assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
    end

    private

    def trap(pokemon)
      CollectionUpdater.new(pokemon_id: pokemon.id, user_id: @user_pokemon.user_id).trap
    end
  end
end
