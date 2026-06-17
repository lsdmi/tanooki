# frozen_string_literal: true

# JSON API for recent messages in the site-wide chat room.
class ChatController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :recent_messages

  def recent_messages
    ActiveStorage::Current.url_options = { host: 'localhost:3000' } if Rails.env.test?
    messages = ChatMessage.includes(:user, user: :avatar)
                          .for_room('general')
                          .recent
                          .reverse

    render json: { messages: serialize_messages(messages) }
  end

  private

  def serialize_messages(messages)
    messages.map(&:as_recent_api_json)
  end
end
