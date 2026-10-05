# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleStartTest < ActiveSupport::TestCase
    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      UserPokemon.create!(user: @attacker, pokemon: pokemons(:two), character: :brave, battle_experience: 40)
      UserPokemon.create!(user: @defender, pokemon: pokemons(:three), character: :hardy, battle_experience: 10)
    end

    test 'fights the pinned opponent and updates both ratings' do
      Matchmaker.new(@attacker).opponent

      assert_equal :fought, BattleStart.new(@attacker).call
      ratings = [@attacker, @defender].map { |user| user.trainer_profile.reload.rating }

      assert_equal [48, 52], ratings.sort
    end

    test 'starts the battle clock for both sides' do
      battle = fight

      assert_equal [battle.created_at] * 2,
                   [@attacker.trainer_profile.reload.last_battle_at, @defender.trainer_profile.reload.last_battle_at]
      assert BattleLeaderboardCooldown.call(@defender)
    end

    test 'stores the battle as data that replays to the same events' do
      battle = fight

      assert_equal [Engine::VERSION, @attacker.id, @defender.id],
                   battle.values_at(:engine_version, :attacker_id, :defender_id)
      assert_equal PokemonBattle.serialize(battle.replay.events), battle.events
      assert_equal battle.replay.attacker_won?, battle.attacker_won?
    end

    test 'stores each team with its species and the rating change per side' do
      battle = fight
      deltas = battle.values_at(:rating_delta_attacker, :rating_delta_defender)

      assert_equal @attacker.user_pokemons.order(:id).pluck(:pokemon_id), battle.attacker_team.pluck('pokemon_id')
      assert_equal battle.attacker_won? ? [2, -2] : [-2, 2], deltas
    end

    test 'saves the experience the engine decided' do
      before = UserPokemon.where(user_id: [@attacker.id, @defender.id]).pluck(:id, :battle_experience).to_h
      result = fight.replay

      assert_not_empty result.experience
      assert_equal before.merge(result.experience),
                   UserPokemon.where(user_id: [@attacker.id, @defender.id]).pluck(:id, :battle_experience).to_h
    end

    test 'no pinned opponent means no battle' do
      assert_no_difference('PokemonBattle.count') do
        assert_equal :no_opponent, BattleStart.new(@attacker).call
      end
    end

    test 'rating failure rolls back the battle and experience' do
      Matchmaker.new(@attacker).opponent
      experience = UserPokemon.where(user_id: [@attacker.id, @defender.id]).pluck(:id, :battle_experience)

      Battle::RatingUpdater.stub(:new, ->(**) { raise ActiveRecord::Deadlocked }) do
        assert_raises(ActiveRecord::Deadlocked) { BattleStart.new(@attacker).call }
      end

      assert_equal 0, PokemonBattle.where(attacker: @attacker).count
      assert_equal experience, UserPokemon.where(user_id: [@attacker.id, @defender.id]).pluck(:id, :battle_experience)
    end

    private

    def fight
      Matchmaker.new(@attacker).opponent
      BattleStart.new(@attacker).call
      PokemonBattle.last
    end
  end
end
