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
  has_one_attached :banner
  has_one_attached :cover
  has_many :fiction_genres, dependent: :destroy
  has_many :fiction_scanlators, dependent: :destroy
  has_many :genres, through: :fiction_genres
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :scanlators, through: :fiction_scanlators
  has_many :users, through: :scanlators

  enum :status, {
    announced: 'Анонсовано',
    dropped: 'Покинуто',
    ongoing: 'Видається',
    finished: 'Завершено'
  }

  enum :origin, {
    unknown: 'невідоме',
    english: 'англійське',
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
  validates :scanlator_ids, presence: { message: 'має бути принаймні одна команда' }
  validates :author, length: { in: 2..50 }
  validates :description, length: { in: 25..1000 }
  validates :short_description, length: { in: 25..120 }, allow_blank: true
  validates :title, length: { in: 3..100 }
  validates :alternative_title, :english_title, length: { maximum: 100 }
  validates :total_chapters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :cover_format

  scope :most_reads, lambda {
    joins(:readings)
      .where(readings: { created_at: 1.year.ago..Time.current })
      .group(:id)
      .order(Arel.sql('COUNT(readings.fiction_id) DESC'))
  }
  scope :recent, -> { where('created_at >= ?', 3.days.ago) }

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
    [title.to_s.downcase]
  end

  def set_dropped_status
    FictionStatusUpdater.new(self).call
  end

  def related_fictions
    Rails.cache.fetch("related-to-#{slug}", expires_in: 24.hours) do
      Fiction.joins(:scanlators)
             .where(scanlators: { id: scanlators.pluck(:id) })
             .includes(:cover_attachment)
             .where.not(id: id)
             .order(views: :desc)
             .distinct
    end
  end

  private

  def cover_format
    return unless cover.attached?

    return if cover.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp])

    errors.add(:cover, 'має бути JPEG, PNG, SVG, або WebP')
  end

  def cleanup_scanlator_ids
    self.scanlator_ids = scanlator_ids&.reject(&:blank?)
  end
end
