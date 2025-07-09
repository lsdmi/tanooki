# frozen_string_literal: true

require 'test_helper'

class ChatChannelTest < ActionCable::Channel::TestCase
  def setup
    @user = users(:user_one)
    @message_content = 'Hello, this is a test message!'
    ActiveStorage::Current.url_options = { host: 'localhost:3000' } if Rails.env.test?
  end

  test 'subscribes to chat_room' do
    subscribe
    assert subscription.confirmed?
    assert_has_stream 'chat_room'
  end

  test 'speak creates a chat message' do
    stub_connection(current_user: @user)
    subscribe
    assert_difference 'ChatMessage.count', 1 do
      perform :speak, message: @message_content
    end
    message = ChatMessage.last
    assert_equal @message_content, message.content
    assert_equal @user, message.user
    assert_equal 'general', message.room
  end

  test 'speak broadcasts a message' do
    stub_connection(current_user: @user)
    subscribe
    assert_broadcasts('chat_room', 1) do
      perform :speak, message: @message_content
    end
  end

  test 'speak does nothing when user is not authenticated' do
    stub_connection(current_user: nil)
    subscribe
    assert_no_difference 'ChatMessage.count' do
      perform :speak, message: @message_content
    end
    assert_no_broadcasts 'chat_room'
  end
end
