# frozen_string_literal: true

class Chapter < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates

  belongs_to :fiction
  belongs_to :user
  has_rich_text :content
  has_many :comments, as: :commentable, dependent: :destroy

  validates :content, length: { minimum: 500 }
  validates :number, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :title, length: { maximum: 100 }

  def author
    fiction.author
  end

  def display_title
    title.presence || "Розділ #{number}"
  end

  def fiction_slug
    fiction.slug
  end

  def fiction_title
    fiction.title
  end

  def slug_candidates
    [
      "#{fiction&.title&.downcase}-rozdil-#{number}"
    ]
  end

  def translator
    fiction.translator
  end
end
