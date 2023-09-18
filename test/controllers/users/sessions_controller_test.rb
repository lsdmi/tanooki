# frozen_string_literal: true

require 'test_helper'

module Users
  class SessionsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    include Devise::Test::IntegrationHelpers

    def setup
      @user = users(:user_one)
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    test 'should create new user session without catch_pokemon' do
      post :create, params: { user: { email: @user.email, password: @user.password } }

      assert_response :ok
      assert_equal 1, UserPokemon.where(user_id: @user.id).count
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
