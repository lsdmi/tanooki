# frozen_string_literal: true

require 'test_helper'

class DashboardsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:user_one)
  end

  test 'should get readings' do
    sign_in @user
    get :notifications
    assert_response :success
    assert_template 'users/dashboard/_notification'
    assert_not_nil assigns(:pagy)
    assert_not_nil assigns(:comments)
  end
end
