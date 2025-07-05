# frozen_string_literal: true

class ChatController < ApplicationController
  before_action :authenticate_user!, only: [:speak]

  def recent_messages
    messages = ChatMessage.includes(:user, user: :avatar)
                          .for_room('general')
                          .recent
                          .reverse

    render json: { messages: serialize_messages(messages) }
  rescue StandardError => e
    Rails.logger.error "Error in recent_messages: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Failed to load messages' }, status: :internal_server_error
  end

  private

  def serialize_messages(messages)
    messages.map { |message| message_data(message) }
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
