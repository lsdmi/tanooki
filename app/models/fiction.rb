# frozen_string_literal: true

# User-submitted novel, web-fiction, or fan-fiction work.
class Fiction < ApplicationRecord
  include FictionPresentation
  include FictionRatings
  include Pagy::Backend
  extend FriendlyId

  acts_as_paranoid
  include SearchkickSoftDeletable
  friendly_id :slug_candidates
  searchkick callbacks: :async
  extend Pagy::Searchkick

  attr_accessor :genre_ids, :scanlator_ids, :user_id

  has_many :chapters, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_one_attached :banner
  has_one_attached :cover
  has_many :fiction_genres, dependent: :destroy
  has_many :fiction_scanlators, dependent: :destroy
  has_many :genres, through: :fiction_genres
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :fiction_ratings, dependent: :destroy
  has_many :scanlators, through: :fiction_scanlators
  has_many :users, through: :scanlators
  has_many :bookshelf_fictions, dependent: :destroy
  has_many :bookshelves, through: :bookshelf_fictions

  enum :status, { announced: 'Анонсовано', dropped: 'Покинуто', ongoing: 'Видається', finished: 'Завершено' }
  enum :origin, { nknown: 'невідоме', english: 'англійське', bosnian: 'боснійське', italian: 'італійське',
                  chinese: 'китайське', korean: 'корейське', dutch: 'нідерландське', polish: 'польське',
                  thai: 'тайське', ukrainian: 'українське', french: 'французьке', japanese: 'японське' }

  before_validation :cleanup_scanlator_ids

  validates :cover, presence: true
  validates :scanlator_ids, presence: true
  validates :author, length: { in: 2..50 }
  validates :description, length: { in: 25..1000 }
  validates :short_description, length: { in: 25..120 }, allow_blank: true
  validates :title, length: { in: 3..100 }
  validates :alternative_title, :english_title, length: { maximum: 100 }
  validates :total_chapters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :cover_format

  scope :most_reads, lambda {
    readings_join_sql = sanitize_sql_array(
      [
        <<~SQL.squish,
          LEFT JOIN (
            SELECT
              fiction_id,
              COUNT(*) AS recent_readings_count
            FROM reading_progresses
            WHERE reading_progresses.created_at BETWEEN ? AND ?
            GROUP BY fiction_id
          ) AS readings_counts ON readings_counts.fiction_id = fictions.id
        SQL
        1.year.ago,
        Time.current
      ]
    )
    select('fictions.*, COALESCE(recent_readings_count, 0) AS recent_readings_count')
      .joins(readings_join_sql)
      .order(Arel.sql('recent_readings_count DESC, fictions.id ASC'))
  }
  scope :recent, -> { where(created_at: 7.days.ago..) }
  scope :safe_content, -> { where(adult_content: false) }

  def search_data
    {
      author:,
      alternative_title:,
      english_title:,
      scanlators: scanlators.pluck(:title).to_sentence,
      title:,
      active: true
    }
  end

  def slug_candidates
    [title.to_s.downcase]
  end

  def set_dropped_status
    Fictions::InactivityDrop.new(self).call
  end

  private

  def cover_format
    return unless cover.attached?

    return if cover.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp])

    errors.add(:cover, :invalid_format)
  end

  def cleanup_scanlator_ids
    self.scanlator_ids =
      if scanlator_ids.nil? && persisted? && scanlators.exists?
        scanlators.ids
      else
        scanlator_ids&.compact_blank
      end
  end
end
