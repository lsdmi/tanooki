# frozen_string_literal: true

require 'test_helper'

# Comment inbox must not run on the main HTML request; badge loads via lazy turbo frame.
class CommentInboxChromeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'signed-in home defers inbox collector to notification badge frame' do
    sign_in users(:user_one)

    Comments::InboxCollector.stub(:new, ->(*) { raise 'inbox should not run on main HTML' }) do
      get root_path
    end

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge[src=?]', notification_badge_path
  end

  test 'signed-in fiction show defers inbox collector' do
    sign_in users(:user_one)

    Comments::InboxCollector.stub(:new, ->(*) { raise 'inbox should not run on fiction show' }) do
      get fiction_path(fictions(:one))
    end

    assert_response :success
  end

  test 'signed-in chapter show has no navbar badge frame' do
    sign_in users(:user_one)

    Comments::InboxCollector.stub(:new, ->(*) { raise 'inbox should not run on chapter show' }) do
      get chapter_path(chapters(:one))
    end

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge', count: 0
  end

  test 'signed-in studio defers inbox on main HTML when not on notifications tab' do
    sign_in users(:user_one)

    Comments::InboxCollector.stub(:new, ->(*) { raise 'inbox should not run on studio blogs tab HTML' }) do
      get studio_index_path
    end

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge[src=?]', notification_badge_path
  end

  test 'guest home has no notification badge frame' do
    Comments::InboxCollector.stub(:new, ->(*) { raise 'inbox should not run for guests' }) do
      get root_path
    end

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge', count: 0
  end

  test 'guest fiction show has no notification badge frame' do
    Comments::InboxCollector.stub(:new, ->(*) { raise 'inbox should not run for guests' }) do
      get fiction_path(fictions(:one))
    end

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge', count: 0
  end

  test 'notification badge loads inbox for signed-in user' do
    sign_in users(:user_one)

    get notification_badge_path

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge'
  end

  test 'notification badge requires authentication' do
    get notification_badge_path

    assert_redirected_to new_user_session_path
  end
end
