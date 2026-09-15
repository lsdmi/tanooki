# frozen_string_literal: true

require_relative '../../config/initializers/telegram_bot'

# Blog-style article or news post.
class Publication < ApplicationRecord
  include NormalizesWhitespace

  extend FriendlyId
  include SoftDeletable

  normalizes_squished :title
  include SearchkickSoftDeletable
  include Draftable

  friendly_id :slug_candidates
  searchkick callbacks: SearchkickCallbacks.mode
  extend Pagy::Searchkick

  attr_accessor :tag_ids

  belongs_to :user
  has_one_attached :cover
  has_rich_text :description
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :publication_tags, dependent: :destroy
  has_many :tags, through: :publication_tags

  validates :cover, presence: true, unless: :draft?
  validates :description, length: { minimum: 500 }, unless: :draft?
  validates :title, length: { maximum: 100 }
  validates :title, length: { minimum: 10 }, unless: :draft?

  validate :cover_format

  scope :highlights, -> { where(highlight: true) }
  scope :weekly, -> { where(created_at: 7.days.ago..) }
  scope :popular, -> { order(views: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  def should_index?
    deleted_at.nil? && published?
  end

  def search_data
    {
      created_at:,
      description: description.to_plain_text[0..15_000],
      tags: tags.pluck(:name).to_sentence,
      title:,
      active: true
    }
  end

  def slug_candidates
    [
      title&.downcase
    ]
  end

  def should_generate_new_friendly_id?
    slug.blank? || (title_changed? && title.present?)
  end

  def cover_format
    return unless cover.attached?
    return if cover.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp image/avif])

    errors.add(:cover, 'має бути JPEG, PNG, SVG, WebP або AVIF')
  end

  def username
    user.name
  end
end
