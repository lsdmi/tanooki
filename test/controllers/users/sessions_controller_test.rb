# frozen_string_literal: true

require 'test_helper'

module Users
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @user.update!(password: 'password', password_confirmation: 'password')
      ActionController::Base.cache_store.clear
    end

    test 'should create new user session without catch_pokemon' do
      post user_session_path, params: { user: { email: @user.email, password: 'password' } }

      assert_response :redirect
      assert_equal 1, UserPokemon.where(user_id: @user.id).count
    end

    test 'rate limits sign in attempts per ip' do
      5.times do
        post user_session_path,
             params: { user: { email: @user.email, password: 'wrong-password' } },
             env: { 'REMOTE_ADDR' => '203.0.113.10' }
      end

      post user_session_path,
           params: { user: { email: @user.email, password: 'wrong-password' } },
           env: { 'REMOTE_ADDR' => '203.0.113.10' }

      assert_response :too_many_requests
    end
  end
end

module Users
  class SessionsIntegrationTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @controller = Users::SessionsController.new
      @session = { pokemon_guest_caught: true, caught_pokemon_id: 2 }
    end

    test 'should create user pokemon and update turbo streams' do
      assert_difference('UserPokemon.count') do
        @controller.stub(:session, @session) do
          @controller.send(:catch_pokemon, @user)
        end
      end
    end
  end
end
