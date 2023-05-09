# frozen_string_literal: true

require_relative '../../config/initializers/telegram_bot'

class Publication < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  attr_accessor :tag_ids

  after_create_commit { TelegramJob.perform_later(self) }

  belongs_to :user
  has_one_attached :cover
  has_rich_text :description
  has_many :comments
  has_many :publication_tags, dependent: :destroy
  has_many :tags, through: :publication_tags

  validates :cover, presence: true
  validates :description, length: { minimum: 1000 }
  validates :title, length: { minimum: 10, maximum: 100 }

  validate :cover_format

  scope :highlights, -> { where(highlight: true) }
  scope :not_highlights, -> { where(highlight: false) }
  scope :last_month, -> { where(created_at: 1.month.ago..) }

  def search_data
    {
      created_at:,
      description: description.to_plain_text,
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
    return if cover.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp])

    errors.add(:cover, 'має бути JPEG, PNG, SVG, або WebP')
  end
end
