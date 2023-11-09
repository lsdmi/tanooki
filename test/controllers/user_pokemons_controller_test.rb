# frozen_string_literal: true

require 'test_helper'

class UserPokemonsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    @pokemon_params = { user_pokemon: { pokemon_id: 2, user_id: 1 }, user_pokemon_id: 1 }
    @user = users(:user_one)
    login_as(@user, scope: :user)
  end

  test 'should create user pokemon and update turbo streams' do
    assert_difference('UserPokemon.count') do
      travel_to Time.zone.local(2004, 11, 24)
      get root_path
      travel_back
      get root_path
      post catch_pokemon_path(format: :turbo_stream), params: @pokemon_params
    end

    assert_response :success
  end

  test 'training should refresh screen on success' do
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_response :success
    assert_select 'turbo-stream[action="update"][target="pokemon-data-screen"]'
  end

  test 'training should refresh error screen on training fraud' do
    @user.update(pokemon_last_training: Time.now)
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_response :success
    assert_select 'turbo-stream[action="update"][target="application-alert"]'
  end
end
