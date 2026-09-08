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
      write_projections(
        listing,
        chapter_count: ChapterSlots.call(listing),
        last_chapter_at: listing.chapters.maximum(Arel.sql(Chapter::PUBLIC_TIME_SQL))
      )
    end

    private

    def write_projections(listing, chapter_count:, last_chapter_at:)
      connection = listing.class.lease_connection
      quoted_time = last_chapter_at.nil? ? 'NULL' : connection.quote(last_chapter_at)

      connection.update(<<~SQL.squish)
        UPDATE #{listing.class.quoted_table_name}
        SET chapter_count = #{Integer(chapter_count)},
            last_chapter_at = #{quoted_time}
        WHERE #{listing.class.quoted_primary_key} = #{Integer(listing.id)}
      SQL

      listing.chapter_count = chapter_count
      listing.last_chapter_at = last_chapter_at
    end
  end
end
