# frozen_string_literal: true

class Fiction < ApplicationRecord
  include Pagy::Backend
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  belongs_to :user
  has_many :chapters, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy, counter_cache: true
  has_one_attached :cover

  enum status: {
    announced: 'Анонсовано',
    dropped: 'Покинуто',
    forbidden: 'Заборонено',
    ongoing: 'Видається',
    finished: 'Завершено'
  }

  validates :cover, presence: true
  validates :author, length: { minimum: 3, maximum: 50 }
  validates :description, length: { minimum: 50, maximum: 750 }
  validates :title, length: { minimum: 3, maximum: 100 }
  validates :alternative_title, length: { maximum: 100 }
  validates :english_title, length: { maximum: 100 }
  validates :total_chapters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :translator, length: { minimum: 3, maximum: 50 }, allow_blank: true

  validate :cover_format

  def search_data
    {
      alternative_title:,
      english_title:,
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
