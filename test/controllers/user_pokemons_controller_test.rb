# frozen_string_literal: true

require 'test_helper'

class UserPokemonsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @pokemon_params = { user_pokemon: { pokemon_id: 2 }, user_pokemon_id: 1 }
    @user = users(:user_one)
    @user.update(pokemon_last_catch: 5.hours.ago, pokemon_last_training: 5.hours.ago)
    sign_in @user
  end

  test 'should create user pokemon and update turbo streams' do
    UserPokemon.where(user_id: 1, pokemon_id: 2).destroy_all

    assert_difference('UserPokemon.count') do
      post catch_pokemon_path(format: :turbo_stream), params: @pokemon_params
    end

    assert_response :success
  end

  test 'should ignore spoofed user id when catching pokemon' do
    other_user = users(:user_two)
    UserPokemon.where(user_id: [@user.id, other_user.id], pokemon_id: 2).destroy_all

    assert_difference -> { @user.user_pokemons.reload.count }, 1 do
      post catch_pokemon_path(format: :turbo_stream), params: {
        user_pokemon: { pokemon_id: 2, user_id: other_user.id }
      }
    end

    assert_response :success
    assert_not UserPokemon.exists?(user_id: other_user.id, pokemon_id: 2)
  end

  test 'guest should not catch pokemon' do
    sign_out @user

    assert_no_difference('UserPokemon.count') do
      post catch_pokemon_path(format: :turbo_stream), params: @pokemon_params
    end

    assert_redirected_to new_user_session_url
  end

  test 'training should refresh screen on success' do
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_response :success
  end

  test 'training should refresh error screen on training fraud' do
    @user.update(pokemon_last_training: Time.zone.now)
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_response :success
  end

  test 'guest should not train pokemon' do
    sign_out @user

    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_redirected_to new_user_session_url
  end

  test 'guest should not regenerate opponent' do
    sign_out @user

    get regenerate_pokemon_opponent_path(format: :turbo_stream)

    assert_redirected_to new_user_session_url
  end
end
