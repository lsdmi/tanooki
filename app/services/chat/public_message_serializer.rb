# frozen_string_literal: true

module Chat
  # Public chat message fields safe for unauthenticated clients.
  class PublicMessageSerializer
    PUBLIC_KEYS = %i[id content user_name user_avatar formatted_time created_at].freeze

    def self.call(message)
      {
        id: message.id,
        content: message.content,
        user_name: message.user.name,
        user_avatar: message.user.chat_avatar_url,
        formatted_time: message.formatted_time,
        created_at: message.created_at
      }
    end
  end
end
