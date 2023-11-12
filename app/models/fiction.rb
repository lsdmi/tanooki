# frozen_string_literal: true

class Fiction < ApplicationRecord
  include Pagy::Backend
  include GenresHelper
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  attr_accessor :genre_ids, :scanlator_ids, :user_id

  after_create_commit { TelegramJob.set(wait: 10.seconds).perform_later(object: self) }

  has_many :chapters, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_one_attached :cover
  has_many :fiction_genres, dependent: :destroy
  has_many :fiction_scanlators, dependent: :destroy
  has_many :genres, through: :fiction_genres
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :scanlators, through: :fiction_scanlators
  has_many :user_fictions, dependent: :destroy
  has_many :users, through: :user_fictions

  enum status: {
    announced: 'Анонсовано',
    dropped: 'Покинуто',
    ongoing: 'Видається',
    finished: 'Завершено'
  }

  before_validation :cleanup_scanlator_ids

  validates :cover, presence: true
  validates :author, length: { minimum: 3, maximum: 50 }
  validates :description, length: { minimum: 50, maximum: 1000 }
  validates :title, length: { minimum: 3, maximum: 100 }
  validates :alternative_title, length: { maximum: 100 }
  validates :english_title, length: { maximum: 100 }
  validates :total_chapters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :cover_format

  scope :most_reads, -> { joins(:readings).group(:fiction_id).order('COUNT(reading_progresses.fiction_id) DESC') }

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

  def set_dropped_status
    return if finished? || chapters.maximum(:created_at).nil? || (Time.now - chapters.maximum(:created_at)) < 90.days

    update(status: Fiction.statuses[:dropped])
  end

  def telegram_fiction_path
    Rails.application.routes.url_helpers.fiction_url(self, host: ApplicationHelper::PRODUCTION_URL)
  end

  def telegram_message
    ActionController::Base.helpers.sanitize(
      "🎉 <b>#{title}</b> 🎉 \n\n" \
      "<i>#{description}</i> \n\n" \
      "✍️ Переклад: <i>#{scanlators.map(&:title).to_sentence}</i> ✍️ \n\n" \
      "🔗 <i><b><a href=\"#{telegram_fiction_path}\">Читати на сайті</a></b></i> 🔗 \n\n" \
      "#{genres.map { |genre| "<i><b>##{genre_formatter(genre)}</b></i>" }.join(', ')}"
    )
  end

  private

  def cleanup_scanlator_ids
    self.scanlator_ids = scanlator_ids&.reject(&:blank?)
  end
end
