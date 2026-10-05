# frozen_string_literal: true

require 'test_helper'

# Opponent reroll and the per-user rate limits shared by catch, training, reroll, and battle.
class PokemonGameActionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @user.trainer_profile.update!(last_catch_at: 5.hours.ago, last_training_at: 5.hours.ago)
    sign_in @user
  end

  test 'reroll pins a new opponent and hides the reroll button' do
    reroll

    assert_equal users(:user_two).id, @user.trainer_profile.reload.pinned_opponent_id
    assert_not_includes response.body, regenerate_pokemon_opponent_path
  end

  test 'second reroll in the window is refused' do
    reroll

    assert_no_changes(-> { @user.trainer_profile.reload.opponent_rerolled_at }) { reroll }
    assert_includes response.body, I18n.t('pokemons.alerts.reroll_used')
  end

  test 'reroll is a POST only' do
    get '/pokemon/opponent/regenerate'

    assert_response :not_found
  end

  test 'rerolls are rate limited per user' do
    6.times { reroll }

    assert_response :too_many_requests
    assert_includes response.body, I18n.t('pokemons.alerts.rate_limited')
  end

  test 'training rate limit does not spend the catch limit' do
    11.times { post training_pokemon_path(format: :turbo_stream), params: { user_pokemon_id: 1 } }

    assert_response :too_many_requests
    post catch_pokemon_path(format: :turbo_stream), params: { encounter: 'expired' }

    assert_response :success
  end

  test 'guest should not regenerate opponent' do
    sign_out @user

    reroll

    assert_redirected_to new_user_session_url
  end

  private

  def reroll
    post regenerate_pokemon_opponent_path(format: :turbo_stream)
  end
end
