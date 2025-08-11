# frozen_string_literal: true

require_relative '../../config/initializers/telegram_bot'

class Publication < ApplicationRecord
  extend FriendlyId
  include TagsHelper
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  attr_accessor :tag_ids

  belongs_to :user
  has_one_attached :cover
  has_rich_text :description
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :publication_tags, dependent: :destroy
  has_many :tags, through: :publication_tags

  validates :cover, presence: true
  validates :description, length: { minimum: 500 }
  validates :title, length: { minimum: 10, maximum: 100 }

  validate :cover_format

  scope :highlights, -> { where(highlight: true) }
  scope :last_month, -> { where(created_at: 1.month.ago..) }
  scope :recent, -> { where(created_at: 5.days.ago..) }
  scope :popular, -> { order(views: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  def search_data
    {
      created_at:,
      description: description.to_plain_text[0..15_000],
      tags: tags.pluck(:name).to_sentence,
      title:
    }
  end

  def slug_candidates
    [
      title.downcase
    ]
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
