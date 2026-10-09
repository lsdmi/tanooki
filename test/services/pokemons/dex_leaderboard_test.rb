# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DexLeaderboardTest < ActiveSupport::TestCase
    setup do
      @leaderboard = DexLeaderboard.new
      @first = users(:user_one)
      @second = users(:user_two)
      @third = User.find(102)

      UserPokemon.create!(
        pokemon_id: pokemons(:one).id,
        user: @third,
        current_level: 1,
        battle_experience: 1,
        character: 'lucky'
      )

      @first.trainer_profile.update!(glicko_rating: 1800, glicko_deviation: 100, last_battle_at: 1.day.ago)
      @second.trainer_profile.update!(glicko_rating: 1700, glicko_deviation: 80, last_battle_at: 1.day.ago)
      @third.trainer_profile.update!(glicko_rating: 1500, glicko_deviation: 80, last_battle_at: 1.day.ago)
    end

    test 'ranks by rating minus two deviations' do
      @first.trainer_profile.update!(glicko_rating: 1900, glicko_deviation: 300)

      assert_equal 3, @leaderboard.rank_for(@first)
      assert_equal 1, @leaderboard.rank_for(@second)
      assert_equal 2, @leaderboard.rank_for(@third)
    end

    test 'tie-breaks an equal floor by user id' do
      @second.trainer_profile.update!(glicko_rating: 1740, glicko_deviation: 70)

      assert_equal 1, @leaderboard.rank_for(@first)
      assert_equal 2, @leaderboard.rank_for(@second)
    end

    test 'ranks a profile just rated by its new rating' do
      @third.trainer_profile.glicko_rating = 2000

      assert_equal 1, @leaderboard.rank_for(@third)
    end

    test 'percentile counts battled trainers ranked strictly lower, so a tie shares one' do
      @second.trainer_profile.update!(glicko_rating: 1500, glicko_deviation: 80)

      assert_in_delta 2.0 / 3, @leaderboard.percentile_for(@first)
      assert_in_delta 0.0, @leaderboard.percentile_for(@second)
      assert_in_delta 0.0, @leaderboard.percentile_for(@third)
    end

    test 'percentile compares with recently active trainers only' do
      @third.trainer_profile.update!(glicko_rating: 2000, last_battle_at: 31.days.ago)

      assert_in_delta 0.5, @leaderboard.percentile_for(@first)
      assert_in_delta 1.0, @leaderboard.percentile_for(@third)
    end

    test 'a trainer who never battled has no percentile' do
      @third.trainer_profile.update!(last_battle_at: nil)

      assert_nil @leaderboard.percentile_for(@third)
    end

    test 'returns nil for users not on the leaderboard' do
      assert_nil @leaderboard.rank_for(User.find(101))
    end

    test 'a rank costs two queries once per user per render' do
      assert_queries_count(2) { 2.times { @leaderboard.rank_for(@first) } }
    end

    test 'every title in a render shares one query' do
      assert_queries_count(1) { [@first, @second, @third].each { |user| @leaderboard.percentile_for(user) } }
    end

    test 'counts and orders a user with several Pokémon once' do
      %i[four five].each do |species|
        UserPokemon.create!(pokemon: pokemons(species), user: @first, current_level: 1, battle_experience: 1,
                            character: 'lucky')
      end

      assert_equal 3, DexLeaderboard.new.rank_for(@third)
      assert_equal [@first, @second, @third], DexLeaderboard.top.map(&:user)
    end
  end
end
