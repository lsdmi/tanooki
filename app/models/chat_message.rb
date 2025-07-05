# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  belongs_to :user

  validates :content, presence: true, length: { maximum: 1000 }
  validates :room, presence: true

  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :for_room, ->(room) { where(room: room) }

  def formatted_time
    created_at.in_time_zone(Rails.application.config.time_zone).strftime('%H:%M')
  end

  def formatted_date
    created_at.in_time_zone(Rails.application.config.time_zone).strftime('%b %d')
  end
end
