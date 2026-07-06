# frozen_string_literal: true

require 'test_helper'

class SessionWatchdogTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'signed in pages render session watchdog' do
    get studio_index_path

    assert_response :success
    assert_select '[data-controller~="session-watchdog"]'
  end

  test 'signed in browse pages render session watchdog' do
    get library_path

    assert_response :success
    assert_select '[data-controller~="session-watchdog"]'
  end

  test 'signed in fiction show renders session watchdog' do
    get fiction_path(fictions(:one))

    assert_response :success
    assert_select '[data-controller~="session-watchdog"]'
  end

  test 'guest pages do not render session watchdog' do
    sign_out users(:user_one)

    get about_path

    assert_response :success
    assert_select '[data-controller~="session-watchdog"]', count: 0
  end
end
