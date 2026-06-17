# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleLeaderboardCooldownTest < ActiveSupport::TestCase
    test 'call returns boolean for a user' do
      result = BattleLeaderboardCooldown.call(users(:user_one))

      assert_includes [true, false], result
    end

    test 'call is true after a new battle even when battle_logs were already loaded' do
      user = users(:user_one)
      defender = users(:user_two)

      user.attacker_battle_logs.to_a
      user.defender_battle_logs.to_a

      PokemonBattleLog.create!(
        attacker: user,
        defender:,
        winner: user
      )

      assert BattleLeaderboardCooldown.call(user)
    end
  end
end
