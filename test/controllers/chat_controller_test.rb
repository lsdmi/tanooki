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
  end

  test 'should get recent_messages' do
    user = users(:user_one)
    message = chat_messages(:one)

    get chat_recent_messages_url

    assert_response :success
    json = response.parsed_body

    assert_kind_of Array, json['messages']

    first = json['messages'].first

    assert_equal [message.content, user.id], [first['content'], first['user_id']]
  end
end
