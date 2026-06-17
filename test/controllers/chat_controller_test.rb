# frozen_string_literal: true

require 'test_helper'

ActiveStorage::Current.url_options = { host: 'localhost:3000' }

class ChatControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :avatars, :chat_messages

  setup do
    avatar = avatars(:one)
    unless avatar.image.attached?
      avatar.image.attach(
        io: Rails.root.join('app/assets/images/logo-default.svg').open,
        filename: 'logo-default.svg',
        content_type: 'image/svg+xml'
      )
    end

    ActionController::Base.cache_store.clear
  end

  test 'guest can get recent_messages without authentication' do
    get chat_recent_messages_url

    assert_response :success
  end

  test 'should get recent_messages with public user fields' do
    message = chat_messages(:one)

    get chat_recent_messages_url

    assert_response :success
    first = response.parsed_body['messages'].first

    assert_equal message.content, first['content']
    assert_equal message.user.name, first['user_name']
  end

  test 'recent_messages payload excludes sensitive user fields' do
    get chat_recent_messages_url

    first = response.parsed_body['messages'].first
    public_keys = Chat::PublicMessageSerializer::PUBLIC_KEYS.map(&:to_s)

    assert_equal public_keys.sort, first.keys.sort
    assert_empty first.keys - public_keys
  end

  test 'rate limits recent_messages per ip' do
    30.times do
      get chat_recent_messages_url, env: { 'REMOTE_ADDR' => '203.0.113.10' }

      assert_response :success
    end

    get chat_recent_messages_url, env: { 'REMOTE_ADDR' => '203.0.113.10' }

    assert_response :too_many_requests
  end
end
