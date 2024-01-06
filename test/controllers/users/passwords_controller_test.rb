# frozen_string_literal: true

require 'test_helper'

module Users
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get new' do
      get new_user_password_path
      assert_response :success
    end
  end
end
