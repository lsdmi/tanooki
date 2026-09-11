# frozen_string_literal: true

module Catalog
  class ListingNudge
    # Which prompt, if any, the listing currently qualifies for.
    module Candidates
      private

      def posted_after_complete_nudge
        return if @listing.completed_at.blank?
        return if @listing.last_chapter_at.blank?
        return unless @listing.last_chapter_at > @listing.completed_at
        return if dismissed_last_chapter?(POSTED_AFTER_COMPLETE)

        build_nudge(POSTED_AFTER_COMPLETE)
      end

      def plan_reached_nudge
        return if @listing.completed_at.present?
        return if @listing.expected_chapters.blank?
        return unless @listing.chapter_count.positive?
        return unless @listing.chapter_count == @listing.expected_chapters
        return if dismissed_plan_reached?

        build_nudge(PLAN_REACHED)
      end

      def stale_plan_nudge
        return if @listing.expected_chapters.blank?
        return unless @listing.chapter_count > @listing.expected_chapters
        return if dismissed_chapter_count?(STALE_PLAN)

        build_nudge(STALE_PLAN)
      end

      def gone_quiet_nudge
        return if @listing.completed_at.present?
        return unless @listing.listing_state == :stale
        return if dismissed_last_chapter?(GONE_QUIET)

        build_nudge(GONE_QUIET)
      end

      def optional_expected_nudge
        return if @listing.completed_at.present?
        return if @listing.expected_chapters.present?
        return if @listing.chapter_count < OPTIONAL_EXPECTED_AFTER
        return if dismissed_chapter_count?(OPTIONAL_EXPECTED)

        build_nudge(OPTIONAL_EXPECTED)
      end

      def adult_content_nudge
        return if @listing.adult_content?
        return if explicit_genre_slugs.empty?
        return if dismissed_adult_content?

        build_nudge(ADULT_CONTENT)
      end

      def missing_genres_nudge
        return unless @listing.chapter_count.positive?
        return if @listing.genres.any?
        return if dismissed_chapter_count?(MISSING_GENRES)

        build_nudge(MISSING_GENRES)
      end
    end
  end
end
