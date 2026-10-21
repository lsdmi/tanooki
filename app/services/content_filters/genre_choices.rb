# frozen_string_literal: true

module ContentFilters
  # Genres a reader may hide. Rating pills are labels, not genres.
  class GenreChoices
    def self.call
      Genre.where.not(name: Genre::RATING_LABELS).order(:name)
    end
  end
end
