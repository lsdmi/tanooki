# frozen_string_literal: true

require 'test_helper'

class PokemonBattlesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @attacker = users(:user_one)
    @defender = users(:user_two)

    sign_in @attacker
  end

  test 'starting a battle fights the pinned opponent' do
    pin_opponent

    post battle_start_path

    assert_response :success
    assert_equal [@attacker.id, @defender.id], PokemonBattle.last.values_at(:attacker_id, :defender_id)
  end

  test 'starting a battle ignores a defender id from the form' do
    pin_opponent

    post battle_start_path, params: { defender: User.find(101).id }

    assert_equal @defender.id, PokemonBattle.last.defender_id
  end

  test 'starting a battle releases the pin' do
    pin_opponent

    post battle_start_path

    assert_nil @attacker.trainer_profile.reload.pinned_opponent_id
  end

  test 'starting a battle refreshes leaderboard to cooldown via turbo stream' do
    pin_opponent

    post battle_start_path(format: :turbo_stream)

    assert_response :success
    assert_includes @response.body, 'Перерва в'
    assert_includes @response.body, 'pokemon-leaderboard-screen'
  end

  test 'starting a battle replaces the top trainers panel' do
    pin_opponent

    post battle_start_path(format: :turbo_stream)

    assert_includes @response.body, 'turbo-stream action="replace" target="pokemon-top-trainers"'
  end

  test 'battle without a pinned opponent is refused' do
    assert_no_difference('PokemonBattle.count') do
      post battle_start_path(format: :turbo_stream), params: { defender: @defender.id }
    end

    assert_includes @response.body, I18n.t('pokemons.alerts.battle_unavailable')
  end

  test 'second battle inside the cooldown is refused' do
    pin_opponent
    post battle_start_path
    pin_opponent

    assert_no_difference('PokemonBattle.count') do
      post battle_start_path(format: :turbo_stream)
    end
  end

  test 'battles are rate limited per user' do
    5.times { post battle_start_path(format: :turbo_stream) }
    post battle_start_path(format: :turbo_stream)

    assert_response :too_many_requests
    assert_includes @response.body, I18n.t('pokemons.alerts.rate_limited')
  end

  test 'guest should not start a battle' do
    sign_out @attacker

    assert_no_difference('PokemonBattle.count') do
      post battle_start_path(format: :turbo_stream)
    end

    assert_redirected_to new_user_session_url
  end

  private

  def pin_opponent
    Pokemons::Matchmaker.new(@attacker.reload).opponent
  end
end
