# frozen_string_literal: true

require 'test_helper'

class PokemonTypeRelationTest < ActiveSupport::TestCase
  test 'type method returns the correct Pokemon type' do
    type_relation = pokemon_type_relations(:one)
    assert_equal pokemon_types(:one), type_relation.type
  end
end
