# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DexLeaderboardTopTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @first = users(:user_one)
      @second = users(:user_two)
      @first.trainer_profile.update!(glicko_rating: 1800, glicko_deviation: 100)
      @second.trainer_profile.update!(glicko_rating: 1700, glicko_deviation: 80)
      create_pokemon_battle(attacker: @first, defender: @second)
    end

    test 'lists trainers in rank order with their title percentile' do
      rows = DexLeaderboard.top.map { |entry| [entry.user, entry.rank, entry.percentile] }

      assert_equal [[@first, 1, 0.5], [@second, 2, 0.0]], rows
    end

    test 'leaves out trainers who have not fought in the open season' do
      third = User.find(102)
      UserPokemon.create!(user: third, pokemon: pokemons(:one), character: :lucky, battle_experience: 1)
      create_pokemon_battle(attacker: @second, defender: third)
      drop_from_season(PokemonBattle.where(attacker: @first, defender: @second))

      rows = DexLeaderboard.top.map { |entry| [entry.user.id, entry.rank] }

      assert_equal [[@second.id, 1], [third.id, 2]], rows
    end

    test 'the place in the top skips trainers outside the season' do
      third = User.find(102)
      UserPokemon.create!(user: third, pokemon: pokemons(:one), character: :lucky, battle_experience: 1)
      create_pokemon_battle(attacker: @second, defender: third)
      drop_from_season(PokemonBattle.where(attacker: @first, defender: @second))
      leaderboard = DexLeaderboard.new

      assert_equal [2, 1], [leaderboard.rank_for(@second), leaderboard.top_place_for(@second)]
      assert_nil leaderboard.top_place_for(@first)
    end

    test 'stays cached until a ranked battle' do
      DexLeaderboard.top
      @second.trainer_profile.update!(glicko_rating: 2000)

      assert_equal @first, DexLeaderboard.top.first.user

      create_pokemon_battle(attacker: @first, defender: @second, ranked: false)

      assert_equal @first, DexLeaderboard.top.first.user

      create_pokemon_battle(attacker: @first, defender: @second)

      assert_equal @second, DexLeaderboard.top.first.user
    end

    test 'loads trainers fresh and drops one deleted since' do
      DexLeaderboard.top
      @first.update!(name: 'Renamed')
      PokemonBattle.involving(@second).delete_all
      @second.destroy!

      rows = DexLeaderboard.top.map { |entry| [entry.user.name, entry.rank] }

      assert_equal [['Renamed', 1]], rows
    end

    test 'a cached top neither ranks again nor loads users one by one' do
      DexLeaderboard.top

      assert_no_queries_match(/trainer_profiles|user_pokemons/) do
        names = DexLeaderboard.top.map { |entry| entry.user.name }

        assert_equal [@first.name, @second.name], names
      end
    end

    private

    def drop_from_season(scope)
      scope.find_each { |battle| battle.update!(pokemon_season: nil) }
    end
  end
end
