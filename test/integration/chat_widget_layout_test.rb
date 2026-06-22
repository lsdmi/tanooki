# frozen_string_literal: true

require 'test_helper'

class ChatWidgetLayoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'guest page renders guest chat shell with turbo permanent' do
    get fictions_path

    assert_response :success
    assert_select '#chat-widget-guest[data-turbo-permanent][data-controller="chat-widget"]', count: 1
    assert_select '#chat-widget-auth', count: 0
  end

  test 'signed in page renders auth chat shell with turbo permanent' do
    sign_in users(:user_one)

    get fictions_path

    assert_response :success
    assert_select '#chat-widget-auth[data-turbo-permanent][data-controller="chat-widget"]', count: 1
    assert_select '#chat-widget-guest', count: 0
  end

  test 'signed in auth shell includes message input' do
    sign_in users(:user_one)

    get fictions_path

    assert_select '#chat-widget-auth [data-chat-widget-target="input"]'
  end

  test 'guest shell omits message input' do
    get fictions_path

    assert_select '#chat-widget-guest [data-chat-widget-target="input"]', count: 0
  end

  test 'chapter reader omits chat widget shells' do
    sign_in users(:user_one)

    get chapter_url(chapters(:one))

    assert_response :success
    assert_select '#chat-widget-guest', count: 0
    assert_select '#chat-widget-auth', count: 0
  end
end
