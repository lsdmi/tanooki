# frozen_string_literal: true

# Fiction genre taxonomy entry.
class Genre < ApplicationRecord
  include NormalizesWhitespace

  extend FriendlyId

  normalizes_squished :name, :description

  # Slugs for genres treated as mature / explicit in tag UI (see SLUG_BY_DISPLAY_NAME migration).
  EXPLICIT_CONTENT_SLUGS = %w[bl gl lgbt harem omegaverse].freeze
  SIXTEEN_LABEL = FictionContentRating::SIXTEEN_LABEL
  ADULT_CONTENT_LABEL = FictionContentRating::EIGHTEEN_LABEL
  RATING_LABELS = [SIXTEEN_LABEL, ADULT_CONTENT_LABEL].freeze
  ORIGINAL_SLUG = 'original'
  FANFICTION_SLUG = 'fanfiction'

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

  def self.rating_tag?(name)
    RATING_LABELS.include?(name.to_s)
  end

  def self.adult_tag?(name, slug: nil)
    rating_tag?(name) || explicit_content?(name: name, slug: slug)
  end

  def self.sort_labels_adult_first(labels, slugs: {})
    order = labels.each_with_index.to_h
    adults, regular = labels.partition { |name| adult_tag?(name, slug: slugs[name] || slugs[name.to_s]) }

    adults.sort_by { |name| [rating_sort_rank(name), order[name]] } + regular
  end

  def self.tag_variant(name: nil, slug: nil)
    case name.to_s
    when SIXTEEN_LABEL then :sixteen
    when ADULT_CONTENT_LABEL then :eighteen
    else
      explicit_content?(name: name, slug: slug) ? :adult : :genre
    end
  end

  def self.rating_sort_rank(name)
    case name.to_s
    when ADULT_CONTENT_LABEL then 0
    when SIXTEEN_LABEL then 1
    else 2
    end
  end
  private_class_method :rating_sort_rank

  def explicit_content?
    self.class.explicit_content?(slug: slug, name: name)
  end
end
