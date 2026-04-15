# frozen_string_literal: true

class Chapter < ApplicationRecord
  extend FriendlyId
  include ChaptersHelper
  acts_as_paranoid
  friendly_id :slug_candidates

  attr_accessor :scanlator_ids

  after_create_commit :manage_users

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

  # When set, this is the moment the chapter becomes visible to everyone (nil = visible as soon as saved).
  validate :published_at_not_in_the_past

  scope :by_user_scanlators, ->(user) { joins(:scanlators).where(scanlators: { id: user.scanlators.ids }) }
  # Visible to the general public now: no schedule, or published_at has passed.
  scope :released, lambda {
    t = arel_table
    where(t[:published_at].eq(nil).or(t[:published_at].lteq(Time.current)))
  }
  # published_at is still in the future — not visible to everyone yet (teams may still see theirs in UI).
  scope :scheduled, lambda {
    where(arel_table[:published_at].gt(Time.current))
  }
  scope :ordered_by_volume_and_number, lambda {
    order(Arel.sql('COALESCE(volume_number, 0), number, chapters.created_at'))
  }

  def author
    fiction.author
  end

  def cover
    fiction.cover
  end

  def display_title
    header = ''
    header += "Том #{check_decimal(volume_number)}. " if volume_number&.nonzero?
    header += "Розділ #{check_decimal(number)}"
    header += " - #{title}" if title.present?
    header
  end

  def display_title_no_volume
    header = ''
    header += "Розділ #{check_decimal(number)}"
    header += " - #{title}" if title.present?
    header
  end

  def fiction_description
    fiction.description
  end

  def fiction_title
    fiction.title
  end

  def fiction_slug
    fiction.slug
  end

  def manage_users
    scanlator_ids.each do |scanlator_id|
      FictionScanlator.find_or_create_by(fiction_id:, scanlator_id:)
    end
  end

  # Not yet visible to the general public (published_at is still in the future).
  def scheduled?
    published_at.present? && published_at > Time.current
  end

  def slug_candidates
    [
      "#{fiction&.title&.downcase}-rozdil-#{number}"
    ]
  end

  private

  def published_at_not_in_the_past
    return if published_at.blank?
    return if published_at >= Time.current
    return if persisted? && !published_at_changed?

    errors.add(:published_at, 'не може бути в минулому')
  end

  def cleanup_scanlator_ids
    self.scanlator_ids = scanlator_ids&.reject(&:blank?)
  end
end
