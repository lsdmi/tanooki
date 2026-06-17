# frozen_string_literal: true

require 'test_helper'

class PokemonBattlesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

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

  test 'starting a battle refreshes leaderboard to cooldown via turbo stream' do
    post battle_start_path(format: :turbo_stream), params: { defender: @defender.id }

    assert_response :success
    assert_includes @response.body, 'Перерва в'
    assert_includes @response.body, 'pokemon-leaderboard-screen'
  end

  test 'guest should not start a battle' do
    sign_out @attacker

    assert_no_difference('PokemonBattleLog.count') do
      post battle_start_path(format: :turbo_stream), params: { defender: @defender.id }
    end

    assert_redirected_to new_user_session_url
  end
end
