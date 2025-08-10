# frozen_string_literal: true

require 'test_helper'

class PokemonBattlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attacker = users(:user_one)
    @defender = users(:user_two)

    sign_in @attacker
  end

  test 'starting a battle' do
    post battle_start_path, params: { defender: @defender.id }

    assert_response :success

    assert_equal 1, PokemonBattleLog.count
  end
end
