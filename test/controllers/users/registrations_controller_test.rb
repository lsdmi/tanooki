# frozen_string_literal: true

require 'test_helper'

module Users
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @user_params = {
        user: {
          avatar_id: 1,
          email: 'test@email.com',
          name: 'John Doe',
          password: 'password',
          password_confirmation: 'password'
        }
      }
    end

    test 'should show confirmation page' do
      get register_path
      assert_response :success
    end

    test 'should create a new user with valid sign-up parameters' do
      assert_difference 'User.count' do
        post register_path, params: @user_params
      end

      assert_redirected_to root_path
      assert_equal I18n.t('devise.registrations.signed_up_but_unconfirmed'), flash[:notice]

      last_user = User.last
      assert_equal @user_params[:user][:name], last_user.name
      assert_equal @user_params[:user][:avatar_id], last_user.avatar_id
      assert_equal @user_params[:user][:email], last_user.email
    end

    test 'should render the sign-up form with invalid parameters' do
      @user_params[:user][:name] = ''
      post register_path, params: @user_params

      assert_response :success
      assert_template :new
      assert_equal 'Перевірте та виправте форму реєстрації:', flash[:alert]
    end
  end
end
