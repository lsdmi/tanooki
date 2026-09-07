# frozen_string_literal: true

module Catalog
  # Writes listing projections from live chapters. Does not touch status or expected_chapters.
  class RefreshChapterStats
    def self.call(fiction)
      new(fiction).call
    end

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      listing = @fiction
      listing.chapters.reset
      listing.update_columns( # rubocop:disable Rails/SkipsModelValidations
        chapter_count: ChapterSlots.call(listing),
        last_chapter_at: listing.chapters.maximum(Arel.sql(Chapter::PUBLIC_TIME_SQL))
      )
    end
  end
end
