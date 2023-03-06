# frozen_string_literal: true

require 'test_helper'

module Admin
  class TalesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      user = users(:user_one)
      host! 'localhost:3000'
      sign_in user
    end

    test 'should get index' do
      get admin_tales_url
      assert_response :success
    end

    test 'should get new' do
      get new_admin_tale_url
      assert_response :success
    end

    test 'should get edit' do
      get edit_admin_tale_url(Tale.first)
      assert_response :success
    end
  end
end
