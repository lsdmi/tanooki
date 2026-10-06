# frozen_string_literal: true

require 'test_helper'

class PokemonEvolutionTest < ActiveSupport::TestCase
  setup do
    @evolution = pokemon_evolutions(:one_to_two)
  end

  test 'an evolution without characters is open to every character' do
    assert(UserPokemon::CHARACTERS.all? { @evolution.for?(it) })
  end

  test 'a branch is open only to its characters' do
    @evolution.update!(characters: %w[brave prideful])

    assert @evolution.for?(:brave)
    assert_not @evolution.for?('lucky')
  end

  test 'next_for finds the branch of the character' do
    @evolution.update!(characters: %w[brave])
    PokemonEvolution.create!(from: pokemons(:one), to: pokemons(:three), min_level: 20, characters: %w[lucky])

    assert_equal pokemons(:three), PokemonEvolution.next_for(pokemons(:one).id, 'lucky').to
    assert_nil PokemonEvolution.next_for(pokemons(:one).id, 'agile')
  end

  test 'min_level must be positive' do
    @evolution.min_level = 0

    assert_not @evolution.valid?
  end
end
