# frozen_string_literal: true

require 'test_helper'

class UserPokemonsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    @pokemon_params = { user_pokemon: { pokemon_id: 1, user_id: 1 } }
    @user = users(:user_one)
    login_as(@user, scope: :user)
  end

  test 'should create user pokemon and update turbo streams' do
    assert_difference('UserPokemon.count') do
      get root_path
      post catch_pokemon_path(format: :turbo_stream), params: @pokemon_params
    end

    assert_response :success
  end
end
