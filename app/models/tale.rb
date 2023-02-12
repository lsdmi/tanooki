# frozen_string_literal: true

class Tale < ApplicationRecord
  extend FriendlyId

  friendly_id :slug_candidates
  searchkick

  has_one_attached :cover
  has_rich_text :description

  has_many :comments, as: :commentable

  validates :title, :description, presence: true

  scope :highlight, -> { where(highlight: true).last }

  def search_data
    {
      title:,
      description: description.to_plain_text
    }
  end

  def slug_candidates
    [
      title.downcase
    ]
  end
end
