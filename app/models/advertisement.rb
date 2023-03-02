# frozen_string_literal: true

class Advertisement < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates

  has_one_attached :cover
  has_rich_text :description

  validates :cover, presence: true
  validates :caption, presence: true, length: { maximum: 50 }
  validates :description, :resource, presence: true, length: { maximum: 300 }

  scope :enabled, -> { where(enabled: true) }

  def slug_candidates
    [
      caption.downcase
    ]
  end
end
