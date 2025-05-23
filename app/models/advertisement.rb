# frozen_string_literal: true

class Advertisement < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates

  has_one_attached :cover
  has_one_attached :poster

  validates :cover, :poster, presence: true
  validates :resource, presence: true, length: { maximum: 300 }

  scope :enabled, -> { where(enabled: true) }

  def slug_candidates
    [
      SecureRandom.hex
    ]
  end
end
