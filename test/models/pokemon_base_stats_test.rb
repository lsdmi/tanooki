# frozen_string_literal: true

require 'test_helper'

class PokemonBaseStatsTest < ActiveSupport::TestCase
  setup { @pokemon = pokemons(:one) }

  test 'blank stats take the official ones for the dex number' do
    @pokemon.assign_attributes(dex_id: 94, base_hp: nil, base_attack: '')

    assert_predicate @pokemon, :valid?
    assert_equal [60, 130], [@pokemon.base_hp, @pokemon.base_attack]
  end

  test 'stats set by hand are kept' do
    @pokemon.update!(dex_id: 94, base_hp: 70, base_attack: 120)

    assert_equal [70, 120], @pokemon.reload.values_at(:base_hp, :base_attack)
  end

  test 'stats outside 1..255 are invalid' do
    @pokemon.assign_attributes(base_hp: 0, base_attack: 256)

    assert_not @pokemon.valid?
    assert_predicate @pokemon.errors[:base_hp], :any?
    assert_predicate @pokemon.errors[:base_attack], :any?
  end

  test 'blank stats stay invalid without official ones for the dex number' do
    @pokemon.assign_attributes(dex_id: 200, base_hp: nil, base_attack: nil)

    assert_not @pokemon.valid?
    assert_predicate @pokemon.errors[:base_hp], :any?
  end
end
