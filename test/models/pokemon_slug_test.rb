# frozen_string_literal: true

require 'test_helper'

class PokemonSlugTest < ActiveSupport::TestCase
  test 'renaming a species regenerates its slug' do
    pokemon = pokemons(:one)
    pokemon.update!(name: 'Ґрауліт')

    assert_equal 'graulit', pokemon.reload.slug
  end

  test 'a taken slug falls back to the dex number' do
    pokemon = pokemons(:two)
    pokemon.update!(name: 'One')

    assert_equal 'one-2', pokemon.reload.slug
  end

  test 'other edits keep the slug' do
    pokemon = pokemons(:one)
    pokemon.update!(rarity: 2)

    assert_equal 'one', pokemon.reload.slug
  end
end
