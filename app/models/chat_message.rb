# frozen_string_literal: true

# Message posted in the site chat.
class ChatMessage < ApplicationRecord
  belongs_to :user

  validates :content, presence: true, length: { maximum: 1000 }
  validates :room, presence: true

  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :for_room, ->(room) { where(room: room) }

  def formatted_time
    created_at.in_time_zone(Rails.application.config.time_zone).strftime('%H:%M')
  end

  def as_recent_api_json
    {
      id: id,
      content: content,
      user_id: user.id,
      user_name: user.name,
      user_avatar: user.chat_avatar_url,
      formatted_time: formatted_time,
      created_at: created_at
    }
  end
end
