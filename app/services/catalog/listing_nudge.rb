# frozen_string_literal: true

module Catalog
  # Team prompts on the listing management page. Never auto-stamps complete.
  class ListingNudge
    include Candidates

    Nudge = Data.define(:kind, :chapter_count, :expected_chapters)

    PLAN_REACHED = :plan_reached
    GONE_QUIET = :gone_quiet
    POSTED_AFTER_COMPLETE = :posted_after_complete
    STALE_PLAN = :stale_plan
    OPTIONAL_EXPECTED = :optional_expected
    ADULT_CONTENT = :adult_content
    MISSING_GENRES = :missing_genres

    # Soft ask only — never required. High enough that the listing is past “just started.”
    OPTIONAL_EXPECTED_AFTER = 10

    def self.for(listing)
      new(listing).current
    end

    def initialize(listing)
      @listing = listing
    end

    def current
      posted_after_complete_nudge || plan_reached_nudge || stale_plan_nudge || gone_quiet_nudge ||
        adult_content_nudge || missing_genres_nudge || optional_expected_nudge
    end

    def complete!
      Catalog::UpdateListingEditorial.call(@listing, complete: true)
      @listing.save!
    end

    def reopen!
      Catalog::UpdateListingEditorial.call(@listing, complete: false)
      @listing.save!
    end

    def raise_expected!
      return unless current&.kind == STALE_PLAN

      Catalog::UpdateListingEditorial.call(@listing, expected: @listing.chapter_count)
      @listing.listing_nudge_dismissals = dismissals.merge(
        STALE_PLAN.to_s => @listing.chapter_count,
        PLAN_REACHED.to_s => @listing.chapter_count
      )
      @listing.save!
    end

    def clear_expected!
      return unless current&.kind == STALE_PLAN

      Catalog::UpdateListingEditorial.call(@listing, expected: nil)
      @listing.save!
    end

    def mark_adult!
      return unless current&.kind == ADULT_CONTENT

      @listing.update!(adult_content: true)
    end

    def dismiss!
      nudge = current
      return unless nudge

      @listing.update!(listing_nudge_dismissals: dismissals.merge(nudge.kind.to_s => dismissal_value_for(nudge.kind)))
    end

    private

    def build_nudge(kind)
      Nudge.new(kind: kind, chapter_count: @listing.chapter_count, expected_chapters: @listing.expected_chapters)
    end

    def dismissed_plan_reached?
      dismissals[PLAN_REACHED.to_s].to_i == @listing.expected_chapters
    end

    def dismissed_chapter_count?(kind)
      dismissals[kind.to_s].to_i == @listing.chapter_count
    end

    def dismissed_adult_content?
      dismissals[ADULT_CONTENT.to_s].to_s == explicit_genre_fingerprint
    end

    def dismissed_last_chapter?(kind)
      return true if @listing.last_chapter_at.blank?

      dismissals[kind.to_s].to_i == @listing.last_chapter_at.to_i
    end

    def dismissal_value_for(kind)
      case kind
      when PLAN_REACHED then @listing.expected_chapters
      when STALE_PLAN, OPTIONAL_EXPECTED, MISSING_GENRES then @listing.chapter_count
      when ADULT_CONTENT then explicit_genre_fingerprint
      when GONE_QUIET, POSTED_AFTER_COMPLETE then @listing.last_chapter_at.to_i
      end
    end

    def explicit_genre_fingerprint
      explicit_genre_slugs.join(',')
    end

    def explicit_genre_slugs
      @listing.genres.filter_map do |genre|
        slug = genre.slug.to_s.downcase
        slug if Genre::EXPLICIT_CONTENT_SLUGS.include?(slug)
      end.sort
    end

    def dismissals
      @listing.listing_nudge_dismissals.presence || {}
    end
  end
end
