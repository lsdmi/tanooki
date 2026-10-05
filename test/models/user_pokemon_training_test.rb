# frozen_string_literal: true

require 'test_helper'

class UserPokemonTrainingTest < ActiveSupport::TestCase
  setup { @pokemon = user_pokemons(:one) }

  test 'a training without a level adds one experience' do
    train(heads: false)

    assert_equal [2, 1], [@pokemon.reload.battle_experience, @pokemon.current_level]
  end

  test 'training experience stops at the cap and never lowers a value above it' do
    @pokemon.update!(battle_experience: 100)
    train(heads: false)

    assert_equal 100, @pokemon.reload.battle_experience
    @pokemon.update!(battle_experience: 115)
    train(heads: false)

    assert_equal 115, @pokemon.reload.battle_experience
  end

  test 'a training with a level adds no experience' do
    train(heads: true)

    assert_equal [1, 2], [@pokemon.reload.battle_experience, @pokemon.current_level]
  end

  private

  def train(heads:)
    @pokemon.stub(:rand, heads ? 0 : 1) { @pokemon.train! }
  end
end
