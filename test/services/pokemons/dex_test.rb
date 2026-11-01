# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DexTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      UserPokemon.where(user: @user).delete_all
      PokemonEncounter.where(user: @user).delete_all
    end

    test 'unknown species stay silhouettes until seen or caught' do
      dex = Dex.new(@user)

      assert_equal Pokemon.count, dex.total_count
      assert_equal 0, dex.caught_count
      assert(dex.entries.all?(&:unknown?))
    end

    test 'an encounter marks the species seen' do
      PokemonEncounter.roll!(pokemon: pokemons(:four), user: @user)
      entry = Dex.new(@user).entries.find { |e| e.pokemon == pokemons(:four) }

      assert_predicate entry, :seen?
      assert_not entry.caught?
    end

    test 'owning a stage marks it and its ancestors caught' do
      UserPokemon.create!(user: @user, pokemon: pokemons(:two), character: :brave)
      by_id = Dex.new(@user).entries.index_by { |e| e.pokemon.id }

      assert_predicate by_id[pokemons(:one).id], :caught?
      assert_predicate by_id[pokemons(:two).id], :caught?
      assert_predicate by_id[pokemons(:three).id], :unknown?
    end

    test 'caught count rises with owned ancestors' do
      UserPokemon.create!(user: @user, pokemon: pokemons(:two), character: :brave)

      assert_equal 2, Dex.new(@user).caught_count
    end

    test 'type filter narrows the grid' do
      fire = PokemonType.create!(key: 'fire')
      PokemonTypeRelation.create!(pokemon: pokemons(:four), pokemon_type: fire)
      UserPokemon.create!(user: @user, pokemon: pokemons(:four), character: :brave)
      dex = Dex.new(@user, type_key: 'fire')

      assert_equal fire, dex.filtered_type
      assert_equal [pokemons(:four)], dex.entries.map(&:pokemon)
      assert_equal 1, dex.total_count
    end

    test 'type completions report caught over total per type' do
      UserPokemon.create!(user: @user, pokemon: pokemons(:one), character: :brave)
      normal = Dex.new(@user).type_completions.find { |c| c.type.key == 'normal' }

      # Fixtures: one, four, five are normal; one is caught.
      assert_equal 1, normal.caught
      assert_equal 3, normal.total
    end

    test 'excluded dex ids stay out of the catalog' do
      stub_const(Dex, :DEX_EXCLUDED_IDS, [pokemons(:five).dex_id]) do
        ids = Dex.new(@user).entries.map { |e| e.pokemon.dex_id }

        assert_not_includes ids, pokemons(:five).dex_id
      end
    end

    test 'completion counts caught species without loading the tile catalog' do
      UserPokemon.create!(user: @user, pokemon: pokemons(:two), character: :brave)
      completion = Dex.completion(@user)

      assert_equal 2, completion.caught
      assert_equal Dex.new(@user).total_count, completion.total
    end
  end
end
