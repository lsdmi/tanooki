# frozen_string_literal: true

module Catalog
  # Distinct catalog chapter "slots" for a listing: floor(number), volumes ignored.
  # 1, 2, 3.1, 3.2 → 3. Soft-deleted rows are out (Chapter default scope).
  # Scheduled chapters still count — they exist on the listing.
  class ChapterSlots
    def self.call(fiction)
      new(fiction).call
    end

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      @fiction.chapters.pluck(:number).map(&:to_i).uniq.size
    end
  end
end
