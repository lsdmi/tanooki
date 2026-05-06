# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class StudioTabTest < ActiveSupport::TestCase
    test 'stores the user' do
      user = users(:user_one)
      tab = StudioTab.new(user)

      assert_equal user, tab.user
    end

    test 'loads pokemons from the same query as UserPokemonListQuery' do
      user = users(:user_one)
      tab = StudioTab.new(user)

      assert_equal UserPokemonListQuery.new(user).call.to_a, tab.pokemons.to_a
    end

    test 'with no pokemons has empty party and no selected pokemon or descendant' do
      user = User.find(101) # users fixture user_101: no user_pokemons rows
      tab = StudioTab.new(user)

      assert_empty tab.pokemons
      assert_nil tab.selected_pokemon
      assert_nil tab.descendant
    end

    test 'with no pokemons leaves dex leaderboard, opponent, and battle history unset' do
      user = User.find(101) # users fixture user_101: no user_pokemons rows
      tab = StudioTab.new(user)

      assert_nil tab.dex_overall
      assert_nil tab.opponent
      assert_nil tab.battle_history
    end

    test 'with pokemons sets selected pokemon and descendant from the first entry' do
      user = users(:user_one)
      tab = StudioTab.new(user)

      first = UserPokemonListQuery.new(user).call.first

      assert_equal first, tab.selected_pokemon
      assert_equal first.pokemon.descendant, tab.descendant
    end

    test 'with pokemons sets battle history from the user' do
      user = users(:user_one)
      tab = StudioTab.new(user)

      assert_same user.latest_battle_log, tab.battle_history
    end

    test 'with pokemons exposes dex leaderboard scope' do
      user = users(:user_one)
      tab = StudioTab.new(user)

      assert_equal User.dex_leaders.to_a, tab.dex_overall.to_a
    end
  end
end
