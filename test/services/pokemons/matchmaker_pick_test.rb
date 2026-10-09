# frozen_string_literal: true

require 'test_helper'

module Pokemons
  # Who the matchmaker offers: active trainers with the nearest ratings, skipping the attacker's recent defenders.
  class MatchmakerPickTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @user = users(:user_one)
      @rival = users(:user_two)
    end

    test 'a trainer idle for the active window is not offered' do
      @rival.trainer_profile.update!(last_training_at: 31.days.ago, last_catch_at: 31.days.ago)

      assert_nil Matchmaker.new(@user).opponent
    end

    test 'catching or attacking makes a trainer active' do
      @rival.trainer_profile.update!(last_training_at: nil, last_catch_at: 1.day.ago)

      assert_equal @rival, Matchmaker.new(@user).opponent

      @rival.trainer_profile.update!(last_catch_at: nil)
      create_pokemon_battle(attacker: @rival, defender: User.find(103), created_at: 1.day.ago)

      assert_equal @rival, Matchmaker.new(@user).tap(&:release!).opponent
    end

    test 'being attacked does not make a trainer active' do
      @rival.trainer_profile.update!(last_training_at: nil)
      create_pokemon_battle(attacker: User.find(103), defender: @rival, created_at: 1.day.ago)

      assert_nil Matchmaker.new(@user).opponent
    end

    test 'offers one of the nearest ratings' do
      @user.trainer_profile.update!(glicko_rating: 1600)
      near = (103..106).map { |id| trainer(id, rating: 1500 + id) }
      far = trainer(107, rating: 2400)
      matchmaker = Matchmaker.new(@user)

      picks = Array.new(20) { matchmaker.tap(&:release!).opponent }

      assert_empty picks - [@rival, *near]
      assert_not_includes picks, far
    end

    test 'skips the last three defenders while anyone else is active' do
      others = (103..105).map { |id| trainer(id) }
      others.each { |other| create_pokemon_battle(attacker: @user, defender: other, created_at: 2.days.ago) }

      assert_equal @rival, Matchmaker.new(@user).opponent
    end

    test 'offers a recent defender when no one else is active' do
      create_pokemon_battle(attacker: @user, defender: @rival, created_at: 2.days.ago)

      assert_equal @rival, Matchmaker.new(@user).opponent
    end

    private

    # An active trainer on the leaderboard with one Pokémon.
    def trainer(id, rating: 1500)
      User.find(id).tap do |user|
        UserPokemon.create!(user:, pokemon: pokemons(:one), character: :brave, battle_experience: 1)
        user.trainer_profile.update!(glicko_rating: rating, last_training_at: 1.day.ago)
      end
    end
  end
end
