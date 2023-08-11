# frozen_string_literal: true

class YoutubeChannel < ApplicationRecord
  has_many :videos, foreign_key: :youtube_channel_id, class_name: 'YoutubeVideo', dependent: :destroy
  has_rich_text :description

  validates :channel_id, :description, :thumbnail, :title, presence: true
end
