# frozen_string_literal: true

# YouTube video entry displayed on the site.
class YoutubeVideo < ApplicationRecord
  include NormalizesWhitespace

  extend FriendlyId
  include SoftDeletable

  normalizes_squished :title
  include SearchkickSoftDeletable
  friendly_id :slug_candidates
  searchkick callbacks: SearchkickCallbacks.mode
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
      title:,
      active: true
    }
  end

  def slug_candidates
    [
      title.downcase
    ]
  end
end
