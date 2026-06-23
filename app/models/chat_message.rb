# frozen_string_literal: true

# Message posted in the site chat.
class ChatMessage < ApplicationRecord
  include NormalizesWhitespace

  normalizes_stripped :content, :room

  belongs_to :user

  validates :content, presence: true, length: { maximum: 1000 }
  validates :room, presence: true

  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :for_room, ->(room) { where(room: room) }

  def formatted_time
    created_at.in_time_zone(Rails.application.config.time_zone).strftime('%H:%M')
  end

  def as_recent_api_json
    Chat::PublicMessageSerializer.call(self)
  end
end
