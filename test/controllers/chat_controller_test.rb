# frozen_string_literal: true

require 'test_helper'

ActiveStorage::Current.url_options = { host: 'localhost:3000' }

class ChatControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :avatars, :chat_messages

  setup do
    avatar = avatars(:one)
    unless avatar.image.attached?
      avatar.image.attach(
        io: File.open(Rails.root.join('app', 'assets', 'images', 'logo-default.svg')),
        filename: 'logo-default.svg',
        content_type: 'image/svg+xml'
      )
    end
  end

  test 'should get recent_messages' do
    user = users(:user_one)
    message = chat_messages(:one)

    get chat_recent_messages_url
    assert_response :success
    json = JSON.parse(response.body)
    assert json['messages'].is_a?(Array)
    assert_equal message.content, json['messages'].first['content']
    assert_equal user.id, json['messages'].first['user_id']
  end
end
