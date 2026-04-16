# frozen_string_literal: true

require 'test_helper'

class ChaptersCalendarControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    get calendar_fictions_path
    assert_response :success
  end

  test 'subscriptions param without sign in shows all updates' do
    get calendar_fictions_path(subscriptions: true)
    assert_response :success
    assert_not assigns(:subscriptions_filter_active)
  end

  test 'subscriptions param with sign in filters calendar' do
    sign_in users(:user_one)
    get calendar_fictions_path(subscriptions: true)
    assert_response :success
    assert assigns(:subscriptions_filter_active)
  end

  test 'subscriptions=1 still activates filter when signed in' do
    sign_in users(:user_one)
    get calendar_fictions_path(subscriptions: 1)
    assert assigns(:subscriptions_filter_active)
  end

  test 'index as turbo_stream replaces calendar frame' do
    get calendar_fictions_path(format: :turbo_stream)
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type
    assert_includes response.body, 'turbo-stream'
    assert_includes response.body, 'chapters_calendar_updates'
  end
end
