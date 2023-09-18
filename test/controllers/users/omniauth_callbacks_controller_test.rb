# frozen_string_literal: true

require 'test_helper'

module Users
  class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @user = users(:user_one)
      @controller = Users::OmniauthCallbacksController.new
    end

    test 'should call success_google_oauth if user is persisted' do
      request = ActionController::TestRequest.new({}, nil, :get)
      request.env['omniauth.auth'] = 'google'

      success_google_oauth_mock = Minitest::Mock.new
      success_google_oauth_mock.expect(:call, nil)

      User.stub(:from_omniauth, @user) do
        @user.stub(:persisted?, true) do
          @controller.stub :request, request do
            @controller.stub(:success_google_oauth, success_google_oauth_mock) do
              @controller.send(:google_oauth2)
            end
          end
        end
      end

      assert_mock(success_google_oauth_mock)
    end

    test 'should call failure_google_oauth if user is not persisted' do
      request = ActionController::TestRequest.new({}, nil, :get)
      request.env['omniauth.auth'] = 'google'

      failure_google_oauth_mock = Minitest::Mock.new
      failure_google_oauth_mock.expect(:call, nil)

      User.stub(:from_omniauth, @user) do
        @user.stub(:persisted?, false) do
          @controller.stub :request, request do
            @controller.stub(:failure_google_oauth, failure_google_oauth_mock) do
              @controller.send(:google_oauth2)
            end
          end
        end
      end

      assert_mock(failure_google_oauth_mock)
    end

    test 'success_google_oauth should set flash notice and sign in the user' do
      request = ActionController::TestRequest.new({}, nil, :get)
      request.flash = { notice: 'My Notice' }

      sign_in_and_redirect_mock = Minitest::Mock.new
      sign_in_and_redirect_mock.expect(:call, nil, [nil], event: :authentication)

      @controller.stub :request, request do
        @controller.stub(:sign_in_and_redirect, sign_in_and_redirect_mock) do
          @controller.stub(:session, {}) do
            @controller.send(:success_google_oauth)
            assert_equal request.flash[:notice], I18n.t('devise.omniauth_callbacks.success', kind: 'Google')
          end
        end
      end

      sign_in_and_redirect_mock.verify
    end
  end
end

module Users
  class OmniauthCallbacksIntegrationTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @controller = Users::OmniauthCallbacksController.new
      @session = { pokemon_guest_caught: true, caught_pokemon_id: 2 }
      @request = ActionController::TestRequest.new({}, nil, :get)
      @request.flash = { notice: 'My Notice' }
    end

    test 'should create user pokemon and update turbo streams' do
      assert_difference('UserPokemon.count') do
        @controller.stub(:session, @session) do
          @controller.stub :request, @request do
            @controller.instance_variable_set(:@user, @user)
            @controller.send(:notice_pokemon_catch)
          end
        end
      end
    end
  end
end
