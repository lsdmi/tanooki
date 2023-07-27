# frozen_string_literal: true

require 'test_helper'

module Users
  class ConfirmationsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers

    def setup
      @user = users(:user_one)
      @user.confirmation_token = 'abcdef'
      @user.save
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    test 'should show confirmation page' do
      get :show, params: { confirmation_token: @user.confirmation_token }
      assert_response :success
    end
  end
end
