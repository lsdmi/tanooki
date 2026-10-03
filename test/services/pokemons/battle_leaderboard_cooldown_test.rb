# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleLeaderboardCooldownTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @user = users(:user_one)
      @rival = users(:user_two)
    end

    test 'off without a recent battle' do
      assert_not BattleLeaderboardCooldown.call(@user)
    end

    test 'on right after a battle, on either side' do
      create_pokemon_battle(attacker: @rival, defender: @user)

      assert BattleLeaderboardCooldown.call(@user)
    end

    test 'off once the cooldown has passed' do
      create_pokemon_battle(attacker: @user, defender: @rival, created_at: (Balance::BATTLE_COOLDOWN + 1.minute).ago)

      assert_not BattleLeaderboardCooldown.call(@user)
    end

    test 'a battle from before pokemon_battles still counts' do
      PokemonBattleLog.create!(attacker: @user, defender: @rival, winner: @user)

      assert BattleLeaderboardCooldown.call(@user)
    end
  end
end
