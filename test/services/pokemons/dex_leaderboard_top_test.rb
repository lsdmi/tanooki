# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DexLeaderboardTopTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @first = users(:user_one)
      @second = users(:user_two)
      @first.trainer_profile.update!(glicko_rating: 1800, glicko_deviation: 100, last_battle_at: 1.day.ago)
      @second.trainer_profile.update!(glicko_rating: 1700, glicko_deviation: 80, last_battle_at: 1.day.ago)
    end

    test 'lists trainers in rank order with their title percentile' do
      rows = DexLeaderboard.top.map { |entry| [entry.user, entry.rank, entry.percentile] }

      assert_equal [[@first, 1, 0.5], [@second, 2, 0.0]], rows
    end

    test 'leaves out trainers who have not battled within the title window' do
      @first.trainer_profile.update!(last_battle_at: (DexLeaderboard::TITLE_WINDOW + 1.day).ago)

      rows = DexLeaderboard.top.map { |entry| [entry.user, entry.rank] }

      assert_equal [[@second, 1]], rows
    end

    test 'the place in the top skips trainers outside the window' do
      @first.trainer_profile.update!(last_battle_at: (DexLeaderboard::TITLE_WINDOW + 1.day).ago)
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

    test 'a cached top neither ranks again nor loads avatars one by one' do
      @second.update!(avatar: avatars(:two))
      [@first, @second].each do |user|
        user.avatar.image.attach(io: file_fixture('cover_valid.webp').open, filename: 'avatar.webp')
      end
      DexLeaderboard.top

      assert_no_queries_match(/trainer_profiles|user_pokemons|active_storage_blobs/) do
        DexLeaderboard.top.each { |entry| entry.user.avatar.image.blob }
      end
    end
  end
end
