# frozen_string_literal: true

class Chapter < ApplicationRecord
  extend FriendlyId
  include ChaptersHelper
  include GenresHelper
  acts_as_paranoid
  friendly_id :slug_candidates

  attr_accessor :scanlator_ids

  after_create_commit :manage_users, :telegram_send_message

  belongs_to :fiction
  belongs_to :user
  has_rich_text :content
  has_many :chapter_scanlators, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :scanlators, through: :chapter_scanlators
  has_many :users, through: :scanlators

  before_validation :cleanup_scanlator_ids

  validates :scanlator_ids, presence: { message: 'мусить бути принаймні одна команда' }
  validates :content, length: { minimum: 500 }
  validates :number, numericality: { greater_than_or_equal_to: 0 }
  validates :volume_number, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :title, length: { maximum: 100 }

  def author
    fiction.author
  end

  def display_title
    header = ''
    header += "Том #{check_decimal(volume_number)}. " if volume_number&.nonzero?
    header += "Розділ #{check_decimal(number)}"
    header += " - #{title}" if title.present?

    header
  end

  def display_chapter_numbers
    volume_text = "Том #{check_decimal(volume_number)}. " if volume_number&.nonzero?
    chapter_text = "Розділ #{check_decimal(number)}"
    "#{volume_text}#{chapter_text}"
  end

  def fiction_description
    fiction.description
  end

  def fiction_slug
    fiction.slug
  end

  def fiction_title
    fiction.title
  end

  def manage_users
    scanlator_ids.each do |scanlator_id|
      FictionScanlator.find_or_create_by(fiction_id:, scanlator_id:)
    end
  end

  def slug_candidates
    [
      "#{fiction&.title&.downcase}-rozdil-#{number}"
    ]
  end

  def telegram_fiction_path
    Rails.application.routes.url_helpers.fiction_url(fiction, host: ApplicationHelper::PRODUCTION_URL)
  end

  def telegram_message
    ActionController::Base.helpers.sanitize(
      "<i>Досі не слідкуєте за <b>\"#{fiction_title}\"<b>?</i> \n\n" \
      "🎉 <i>Насолоджуйтеся <b>#{fiction.chapters.size}</b> розділами неймовірних пригод за " \
      "<i><b><a href=\"#{telegram_fiction_path}\">посиланням</a></b></i>!</i> 🎉 \n\n" \
      "<i>#{fiction_description}</i> \n\n" \
      "✍️ Переклад: <i>#{scanlators.map(&:title).to_sentence}</i> ✍️ \n\n" \
      "#{fiction.genres.map { |genre| "<i><b>##{genre_formatter(genre)}</b></i>" }.join(', ')}"
    )
  end

  def telegram_send_message
    return unless (fiction.chapters.size % 25).zero?

    TelegramJob.set(wait: 10.seconds).perform_later(object: self)
  end

  private

  def cleanup_scanlator_ids
    self.scanlator_ids = scanlator_ids&.reject(&:blank?)
  end
end
