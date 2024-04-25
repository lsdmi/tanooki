# frozen_string_literal: true

class Fiction < ApplicationRecord
  include Pagy::Backend
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  attr_accessor :genre_ids, :scanlator_ids, :user_id

  has_many :chapters, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_one_attached :cover
  has_many :fiction_genres, dependent: :destroy
  has_many :fiction_scanlators, dependent: :destroy
  has_many :genres, through: :fiction_genres
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :scanlators, through: :fiction_scanlators
  has_many :users, through: :scanlators

  enum status: {
    announced: 'Анонсовано',
    dropped: 'Покинуто',
    ongoing: 'Видається',
    finished: 'Завершено'
  }

  enum origin: {
    unknown: 'невідоме',
    bosnian: 'боснійське',
    italian: 'італійське',
    chinese: 'китайське',
    korean: 'корейське',
    dutch: 'нідерландське',
    polish: 'польське',
    thai: 'тайське',
    ukrainian: 'українське',
    french: 'французьке',
    japanese: 'японське'
  }

  before_validation :cleanup_scanlator_ids

  validates :cover, presence: true
  validates :scanlator_ids, presence: { message: 'мусить бути принаймні одна команда' }
  validates :author, length: { minimum: 2, maximum: 50 }
  validates :description, length: { minimum: 25, maximum: 1000 }
  validates :title, length: { minimum: 3, maximum: 100 }
  validates :alternative_title, length: { maximum: 100 }
  validates :english_title, length: { maximum: 100 }
  validates :total_chapters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :cover_format

  scope :most_reads, lambda {
    joins(:readings)
      .where(readings: { created_at: 1.year.ago..Time.now })
      .group(:fiction_id)
      .order('COUNT(readings.fiction_id) DESC')
  }

  scope :recent, -> { where(created_at: 3.days.ago..) }
  scope :recent_chapters, lambda {
    joins(:chapters)
      .joins(:readings)
      .where('chapters.created_at >= ?', 12.hours.ago)
      .group('fictions.id')
      .order('COUNT(reading_progresses.fiction_id) DESC')
  }

  def search_data
    {
      author:,
      alternative_title:,
      english_title:,
      scanlators: scanlators.pluck(:title).to_sentence,
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

  def set_dropped_status
    return if finished? || chapters.maximum(:created_at).nil? || (Time.now - chapters.maximum(:created_at)) < 90.days

    update(status: Fiction.statuses[:dropped])
  end

  private

  def cleanup_scanlator_ids
    self.scanlator_ids = scanlator_ids&.reject(&:blank?)
  end
end
