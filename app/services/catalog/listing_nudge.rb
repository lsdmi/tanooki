# frozen_string_literal: true

module Catalog
  # Team prompts on the listing management page. Never auto-stamps complete.
  class ListingNudge
    Nudge = Data.define(:kind, :chapter_count, :expected_chapters)

    PLAN_REACHED = :plan_reached
    GONE_QUIET = :gone_quiet
    POSTED_AFTER_COMPLETE = :posted_after_complete
    STALE_PLAN = :stale_plan

    def self.for(listing)
      new(listing).current
    end

    def initialize(listing)
      @listing = listing
    end

    def current
      posted_after_complete_nudge || plan_reached_nudge || stale_plan_nudge || gone_quiet_nudge
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

    def dismiss!
      nudge = current
      return unless nudge

      @listing.update!(listing_nudge_dismissals: dismissals.merge(nudge.kind.to_s => dismissal_value_for(nudge.kind)))
    end

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
      return if dismissed_stale_plan?

      build_nudge(STALE_PLAN)
    end

    def gone_quiet_nudge
      return if @listing.completed_at.present?
      return unless @listing.listing_state == :stale
      return if dismissed_last_chapter?(GONE_QUIET)

      build_nudge(GONE_QUIET)
    end

    def build_nudge(kind)
      Nudge.new(kind: kind, chapter_count: @listing.chapter_count, expected_chapters: @listing.expected_chapters)
    end

    def dismissed_plan_reached?
      dismissals[PLAN_REACHED.to_s].to_i == @listing.expected_chapters
    end

    def dismissed_stale_plan?
      dismissals[STALE_PLAN.to_s].to_i == @listing.chapter_count
    end

    def dismissed_last_chapter?(kind)
      return true if @listing.last_chapter_at.blank?

      dismissals[kind.to_s].to_i == @listing.last_chapter_at.to_i
    end

    def dismissal_value_for(kind)
      case kind
      when PLAN_REACHED then @listing.expected_chapters
      when STALE_PLAN then @listing.chapter_count
      when GONE_QUIET, POSTED_AFTER_COMPLETE then @listing.last_chapter_at.to_i
      end
    end

    def dismissals
      @listing.listing_nudge_dismissals.presence || {}
    end
  end
end
