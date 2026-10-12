# frozen_string_literal: true

module Fictions
  # The page a duplicate group should keep: the one still publishing, else the one with more chapters,
  # else the one with more bookmarks.
  class DuplicateSurvivor
    def self.call(fictions, readers:)
      new(fictions, readers).call
    end

    def initialize(fictions, readers)
      @fictions = fictions
      @readers = readers
    end

    def call
      pool = @fictions.select { |fiction| fiction.listing_state == :ongoing }
      (pool.presence || @fictions).max_by { |fiction| score(fiction) }
    end

    private

    def score(fiction)
      [fiction.chapter_count.to_i, @readers.fetch(fiction.id, 0), -fiction.id.to_i]
    end
  end
end
