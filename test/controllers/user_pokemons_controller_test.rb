# frozen_string_literal: true

require 'test_helper'

class UserPokemonsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @pokemon_params = { user_pokemon: { pokemon_id: 2, user_id: 1 }, user_pokemon_id: 1 }
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

  test 'training should refresh screen on success' do
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params
    assert_response :success
  end

  test 'training should refresh error screen on training fraud' do
    @user.update(pokemon_last_training: Time.now)
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params
    assert_response :success
  end
end
