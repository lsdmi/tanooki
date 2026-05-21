# frozen_string_literal: true

# YouTube channel synced for the video section.
class YoutubeChannel < ApplicationRecord
  has_many :videos, class_name: 'YoutubeVideo', inverse_of: :youtube_channel, dependent: :destroy
  has_rich_text :description

  validates :channel_id, :description, :thumbnail, :title, presence: true
end
