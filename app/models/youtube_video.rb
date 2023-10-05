# frozen_string_literal: true

class YoutubeVideo < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  belongs_to :youtube_channel

  has_rich_text :description
  has_many :comments, as: :commentable, dependent: :destroy

  validates :description, :published_at, :title, :thumbnail, :youtube_channel, :video_id, presence: true

  scope :last_month, -> { where(published_at: 1.month.ago..) }

  def search_data
    {
      published_at:,
      description: description.to_plain_text,
      tags:,
      title:
    }
  end

  def slug_candidates
    [
      title.downcase
    ]
  end
end
