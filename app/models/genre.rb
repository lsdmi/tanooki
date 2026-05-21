# frozen_string_literal: true

# Fiction genre taxonomy entry.
class Genre < ApplicationRecord
  extend FriendlyId

  friendly_id :slug_candidates

  has_many :fiction_genres, dependent: :destroy
  has_many :fictions, through: :fiction_genres

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }

  def slug_candidates
    [name.to_s.downcase]
  end

  # Badge files are `public/badges/{slug}.webp` — uses DB `slug` for the matching genre name.
  def self.badge_asset_slug(name)
    return if name.blank?

    find_by(name:)&.slug.presence
  end

  def self.resolve_from_slug_param(param)
    friendly.find(param)
  end
end
