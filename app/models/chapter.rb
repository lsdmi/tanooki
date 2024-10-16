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

  scope :by_user_scanlators, ->(user) { joins(:scanlators).where(scanlators: { id: user.scanlators.ids }) }
  scope :ordered_by_volume_and_number, lambda {
    order(Arel.sql('COALESCE(volume_number, 0), number, chapters.created_at'))
  }
  scope :recent, -> { where(created_at: 12.hours.ago..) }

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

  private

  def cleanup_scanlator_ids
    self.scanlator_ids = scanlator_ids&.reject(&:blank?)
  end
end
