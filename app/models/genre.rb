# frozen_string_literal: true

# Fiction genre taxonomy entry.
class Genre < ApplicationRecord
  include NormalizesWhitespace

  extend FriendlyId

  normalizes_squished :name, :description

  # Slugs for genres treated as mature / explicit in tag UI (see SLUG_BY_DISPLAY_NAME migration).
  EXPLICIT_CONTENT_SLUGS = %w[bl gl lgbt harem omegaverse].freeze
  ADULT_CONTENT_LABEL = '18+'

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

  def self.explicit_content?(name: nil, slug: nil)
    normalized_slug = slug.to_s.downcase.presence
    return EXPLICIT_CONTENT_SLUGS.include?(normalized_slug) if normalized_slug

    return false if name.blank?

    record = find_by(name: name)
    return EXPLICIT_CONTENT_SLUGS.include?(record.slug.to_s.downcase) if record

    false
  end

  def self.adult_tag?(name, slug: nil)
    name.to_s == ADULT_CONTENT_LABEL || explicit_content?(name: name, slug: slug)
  end

  def self.sort_labels_adult_first(labels, slugs: {})
    order = labels.each_with_index.to_h
    adults, regular = labels.partition { |name| adult_tag?(name, slug: slugs[name] || slugs[name.to_s]) }

    adults.sort_by { |name| [name == ADULT_CONTENT_LABEL ? 0 : 1, order[name]] } + regular
  end

  def self.tag_variant(name: nil, slug: nil)
    adult_tag?(name, slug: slug) ? :adult : :genre
  end

  def explicit_content?
    self.class.explicit_content?(slug: slug, name: name)
  end
end
