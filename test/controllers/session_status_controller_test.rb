# frozen_string_literal: true

require 'test_helper'

class SessionStatusControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'show returns authenticated true for signed in user' do
    sign_in users(:user_one)

    get session_status_path, headers: { 'Accept' => 'application/json' }

    assert_response :success
    assert_equal({ 'authenticated' => true }, response.parsed_body)
  end

  test 'show returns authenticated false for guest' do
    get session_status_path, headers: { 'Accept' => 'application/json' }

    assert_response :success
    assert_equal({ 'authenticated' => false }, response.parsed_body)
  end
end
