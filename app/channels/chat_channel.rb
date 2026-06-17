# frozen_string_literal: true

# Streams the general chat room and broadcasts new messages to subscribers.
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'chat_room'
  end

  def unsubscribed; end

  def speak(data)
    return unless current_user

    message = ChatMessage.create!(
      user: current_user,
      content: data['message'],
      room: 'general'
    )

    broadcast_message(message)
  end

  private

  def broadcast_message(message)
    ActiveStorage::Current.url_options = { host: 'localhost:3000' } if Rails.env.test?
    ActionCable.server.broadcast 'chat_room', Chat::PublicMessageSerializer.call(message)
  end
end
