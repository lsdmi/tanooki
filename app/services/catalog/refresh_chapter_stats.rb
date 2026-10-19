# frozen_string_literal: true

module Catalog
  # Writes listing projections from live chapters. Does not touch status or expected_chapters.
  # chapter_count and last_chapter_at both ignore chapters that are still scheduled.
  class RefreshChapterStats
    def self.call(fiction)
      new(fiction).call
    end

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      @fiction.chapters.reset
      write_projections(
        @fiction,
        chapter_count: ChapterSlots.call(@fiction),
        last_chapter_at: @fiction.chapters.released.maximum(Arel.sql(Chapter::PUBLIC_TIME_SQL))
      )
    end

    private

    def write_projections(listing, chapter_count:, last_chapter_at:)
      stamped_at = Time.current
      persist_projections(listing, chapter_count:, last_chapter_at:, stamped_at:)
      listing.assign_attributes(chapter_count:, last_chapter_at:, updated_at: stamped_at)
    end

    def persist_projections(listing, chapter_count:, last_chapter_at:, stamped_at:)
      connection = listing.class.lease_connection
      quoted_time = last_chapter_at.nil? ? 'NULL' : connection.quote(last_chapter_at)
      connection.update(<<~SQL.squish)
        UPDATE #{listing.class.quoted_table_name}
        SET chapter_count = #{Integer(chapter_count)},
            last_chapter_at = #{quoted_time},
            updated_at = #{connection.quote(stamped_at)}
        WHERE #{listing.class.quoted_primary_key} = #{Integer(listing.id)}
      SQL
    end
  end
end
