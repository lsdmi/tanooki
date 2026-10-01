# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleStartTest < ActiveSupport::TestCase
    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
    end

    test 'fights the pinned opponent and updates both ratings' do
      Matchmaker.new(@attacker).opponent

      assert_equal :fought, BattleStart.new(@attacker).call
      assert_equal [52, 48].sort, [@attacker.reload.battle_win_rate, @defender.reload.battle_win_rate].sort
    end

    test 'no pinned opponent means no battle' do
      assert_no_difference('PokemonBattleLog.count') do
        assert_equal :no_opponent, BattleStart.new(@attacker).call
      end
    end

    test 'rating failure rolls back the log and experience' do
      Matchmaker.new(@attacker).opponent
      experience = UserPokemon.where(user_id: [@attacker.id, @defender.id]).pluck(:id, :battle_experience)

      Battle::RatingUpdater.stub(:new, ->(**) { raise ActiveRecord::Deadlocked }) do
        assert_raises(ActiveRecord::Deadlocked) { BattleStart.new(@attacker).call }
      end

      assert_equal 0, PokemonBattleLog.where(attacker: @attacker).count
      assert_equal experience, UserPokemon.where(user_id: [@attacker.id, @defender.id]).pluck(:id, :battle_experience)
    end
  end
end
