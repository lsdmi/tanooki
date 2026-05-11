# frozen_string_literal: true

require 'test_helper'

module Users
  class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @user.confirmation_token = 'abcdef'
      @user.save!
    end

    test 'should show confirmation page' do
      get user_confirmation_path, params: { confirmation_token: @user.reload.confirmation_token }

      assert_response :success
    end
  end
end
