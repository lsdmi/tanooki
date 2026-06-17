# frozen_string_literal: true

require 'test_helper'

module Chat
  class PublicMessageSerializerTest < ActiveSupport::TestCase
    setup do
      ActiveStorage::Current.url_options = { host: 'localhost:3000' }
      avatar = avatars(:one)
      unless avatar.image.attached?
        avatar.image.attach(
          io: Rails.root.join('app/assets/images/logo-default.svg').open,
          filename: 'logo-default.svg',
          content_type: 'image/svg+xml'
        )
      end
    end

    test 'includes only public message fields' do
      message = chat_messages(:one)
      payload = PublicMessageSerializer.call(message)

      assert_equal PublicMessageSerializer::PUBLIC_KEYS.sort, payload.keys.sort
      assert_equal message.content, payload[:content]
      assert_equal message.user.name, payload[:user_name]
    end
  end
end
