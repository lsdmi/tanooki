# frozen_string_literal: true

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
    ActionCable.server.broadcast 'chat_room', message_data(message)
  end

  def message_data(message)
    {
      id: message.id,
      content: message.content,
      user_id: message.user.id,
      user_name: message.user.name,
      user_avatar: user_avatar_url(message.user),
      formatted_time: message.formatted_time,
      created_at: message.created_at
    }
  end

  def user_avatar_url(user)
    user.avatar&.image&.attached? ? user.avatar.image.url : nil
  end
end
