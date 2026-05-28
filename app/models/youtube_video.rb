# frozen_string_literal: true

# YouTube video entry displayed on the site.
class YoutubeVideo < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async
  extend Pagy::Searchkick

  belongs_to :youtube_channel, inverse_of: :videos

  has_rich_text :description
  has_many :comments, as: :commentable, dependent: :destroy

  validates :description, :published_at, :title, :thumbnail, :video_id, presence: true

  scope :last_week, -> { where(published_at: 1.week.ago..) }
  scope :last_month, -> { where(published_at: 1.month.ago..) }

  delegate :title, to: :youtube_channel, prefix: true

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
