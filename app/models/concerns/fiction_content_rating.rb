# frozen_string_literal: true

# Ordinal audience band. 16+ is a label; 18+ is the existing age gate.
module FictionContentRating
  extend ActiveSupport::Concern

  SIXTEEN_LABEL = '16+'
  EIGHTEEN_LABEL = '18+'

  included do
    enum :content_rating, { everyone: 0, sixteen: 16, eighteen: 18 }, prefix: true, default: :everyone, validate: true

    scope :rated_at_most, ->(band) { where(content_rating: ..band) }
    scope :not_eighteen, -> { rated_at_most(content_ratings[:sixteen]) }
    scope :safe_content, -> { not_eighteen }
  end

  # Studio nudge still stamps 18+ through this boolean until the rating prompt lands.
  # False clears eighteen only, so sixteen is not wiped.
  def adult_content=(value)
    if ActiveModel::Type::Boolean.new.cast(value)
      self.content_rating = :eighteen
    elsif content_rating_eighteen?
      self.content_rating = :everyone
    end
  end

  def adult_content?
    content_rating_eighteen?
  end

  def age_gated?
    content_rating_eighteen?
  end

  def age_labelled?
    !content_rating_everyone?
  end

  def content_rating_label
    case content_rating
    when 'sixteen' then SIXTEEN_LABEL
    when 'eighteen' then EIGHTEEN_LABEL
    end
  end

  def with_content_rating_tag_labels(genre_names)
    label = content_rating_label
    label ? [label, *genre_names] : Array(genre_names)
  end

  def with_content_rating_genre_links(genre_links)
    label = content_rating_label
    label ? [{ name: label, slug: nil }, *genre_links] : Array(genre_links)
  end
end
