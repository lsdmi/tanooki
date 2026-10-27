# frozen_string_literal: true

module Catalog
  # Writes listing projections from live chapters. Does not touch expected_chapters or completed_at.
  # Clears paused_at when a newer public chapter exists, or when no public chapters remain.
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
      attributes = { chapter_count:, last_chapter_at:, updated_at: stamped_at }
      attributes[:paused_at] = nil if pause_ended?(listing, chapter_count:, last_chapter_at:)
      listing.assign_attributes(attributes)
    end

    def persist_projections(listing, chapter_count:, last_chapter_at:, stamped_at:)
      connection = listing.class.lease_connection
      quoted_time = last_chapter_at.nil? ? 'NULL' : connection.quote(last_chapter_at)
      connection.update(projection_sql(listing, connection, Integer(chapter_count), quoted_time, stamped_at))
    end

    def projection_sql(listing, connection, count, quoted_time, stamped_at)
      <<~SQL.squish
        UPDATE #{listing.class.quoted_table_name}
        SET chapter_count = #{count},
            last_chapter_at = #{quoted_time},
            paused_at = #{cleared_pause_sql(quoted_time, count)},
            updated_at = #{connection.quote(stamped_at)}
        WHERE #{listing.class.quoted_primary_key} = #{Integer(listing.id)}
      SQL
    end

    # A newer public chapter, or none left, ends the pause. Otherwise the stored timestamp stays.
    def cleared_pause_sql(quoted_time, count)
      <<~SQL.squish
        CASE
          WHEN #{count} = 0 THEN NULL
          WHEN #{quoted_time} IS NOT NULL AND #{quoted_time} > paused_at THEN NULL
          ELSE paused_at
        END
      SQL
    end

    def pause_ended?(listing, chapter_count:, last_chapter_at:)
      return false if listing.paused_at.blank?
      return true if chapter_count.to_i.zero?
      return false if last_chapter_at.blank?

      last_chapter_at > listing.paused_at
    end
  end
end
