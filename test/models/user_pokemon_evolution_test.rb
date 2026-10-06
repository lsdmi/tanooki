# frozen_string_literal: true

require 'test_helper'

class UserPokemonEvolutionTest < ActiveSupport::TestCase
  include PokemonEvolutionLineHelpers

  setup do
    make_three_stage_line(stage_two_at: 16, stage_three_at: 32)
    @user_pokemon = user_pokemons(:one)
  end

  test 'level up evolves on reaching the level' do
    @user_pokemon.update!(current_level: 15)

    assert @user_pokemon.level_up!
    assert_equal pokemons(:two), @user_pokemon.reload.pokemon
  end

  test 'level up below the level keeps the species' do
    assert_not @user_pokemon.level_up!
    assert_equal pokemons(:one), @user_pokemon.reload.pokemon
  end

  test 'a Pokémon past several thresholds evolves through every stage' do
    @user_pokemon.update!(current_level: 40)

    assert_equal pokemons(:three), @user_pokemon.ready_species
  end

  test 'a branched species evolves along the branch of the Pokémon character' do
    evolve_into(pokemons(:one), pokemons(:two), 16, characters: %w[brave])
    evolve_into(pokemons(:one), pokemons(:three), 16, characters: %w[lucky])
    @user_pokemon.update!(current_level: 20)
    brave = user_pokemons(:two).tap { it.update!(character: 'brave', current_level: 20) }

    assert_equal pokemons(:three), @user_pokemon.ready_species
    assert_equal pokemons(:two), brave.ready_species
    assert_equal pokemons(:three), @user_pokemon.next_evolution.to
  end

  test 'a Pokémon whose character no branch takes stays as it is' do
    evolve_into(pokemons(:one), pokemons(:two), 16, characters: %w[brave])
    @user_pokemon.update!(current_level: 20)

    assert_nil @user_pokemon.next_evolution
    assert_equal pokemons(:one), @user_pokemon.ready_species
  end

  test 'a final form never evolves' do
    @user_pokemon.update!(pokemon: pokemons(:three), current_level: 99)

    @user_pokemon.evolve_if_ready!

    assert_equal pokemons(:three), @user_pokemon.reload.pokemon
  end
end
