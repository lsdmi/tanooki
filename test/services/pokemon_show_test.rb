# frozen_string_literal: true

require 'test_helper'

class PokemonShowTest < ActiveSupport::TestCase
  test 'stores the user' do
    user = users(:user_one)
    show = PokemonShow.new(user)

    assert_equal user, show.user
  end

  test 'loads pokemons from the same query as UserPokemonListQuery' do
    user = users(:user_one)
    show = PokemonShow.new(user)

    assert_equal UserPokemonListQuery.new(user).call.to_a, show.pokemons.to_a
  end

  test 'with no pokemons does not assign pokemon-specific readers' do
    user = User.find(101) # users fixture user_101: no user_pokemons rows
    show = PokemonShow.new(user)

    assert_empty show.pokemons
    assert_nil show.selected_pokemon
    assert_nil show.descendant
    assert_nil show.dex_overall
    assert_nil show.opponent
    assert_nil show.battle_history
  end

  test 'with pokemons sets selected pokemon and descendant from the first entry' do
    user = users(:user_one)
    show = PokemonShow.new(user)

    first = UserPokemonListQuery.new(user).call.first
    assert_equal first, show.selected_pokemon
    assert_equal first.pokemon.descendant, show.descendant
  end

  test 'with pokemons sets battle history from the user' do
    user = users(:user_one)
    show = PokemonShow.new(user)

    assert_same user.latest_battle_log, show.battle_history
  end

  test 'with pokemons exposes dex leaderboard scope' do
    user = users(:user_one)
    show = PokemonShow.new(user)

    assert_equal User.dex_leaders.to_a, show.dex_overall.to_a
  end
end
