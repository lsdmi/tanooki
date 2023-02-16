# frozen_string_literal: true

class Publication < ApplicationRecord
  extend FriendlyId

  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick

  belongs_to :user

  has_one_attached :cover
  has_rich_text :description

  has_many :comments

  validates :title, :description, :cover, presence: true

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
