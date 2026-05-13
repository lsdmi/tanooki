# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleLeaderboardCooldownTest < ActiveSupport::TestCase
    test 'call returns boolean for a user' do
      result = BattleLeaderboardCooldown.call(users(:user_one))

      assert_includes [true, false], result
    end
  end
end
