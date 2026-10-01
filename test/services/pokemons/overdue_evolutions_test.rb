# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class OverdueEvolutionsTest < ActiveSupport::TestCase
    include PokemonEvolutionLineHelpers

    setup do
      make_three_stage_line(stage_two_at: 16, stage_three_at: 32)
      @stuck = user_pokemons(:one)
      @stuck.update!(pokemon: pokemons(:two), current_level: 38)
    end

    test 'dry run reports the stuck Pokémon without changing it' do
      rows = OverdueEvolutions.call

      reported = rows.map { |row| [row.user_pokemon_id, row.from, row.to] }

      assert_equal [[@stuck.id, 'Second', 'Third']], reported
      assert_equal pokemons(:two), @stuck.reload.pokemon
    end

    test 'apply evolves it' do
      OverdueEvolutions.call(apply: true)

      assert_equal pokemons(:three), @stuck.reload.pokemon
    end

    test 'a Pokémon below its level is left alone' do
      @stuck.update!(current_level: 20)

      assert_empty OverdueEvolutions.call
    end
  end
end
