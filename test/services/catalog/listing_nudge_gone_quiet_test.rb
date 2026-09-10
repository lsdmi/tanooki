# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeGoneQuietTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.update!(chapter_count: 5, expected_chapters: 5, completed_at: nil, listing_nudge_dismissals: {})
    end

    test 'gone quiet when last chapter is older than STALE_AFTER and listing is not complete' do
      last_public = FictionListingProgress::STALE_AFTER.ago - 1.day
      @fiction.update!(expected_chapters: nil, last_chapter_at: last_public)

      nudge = ListingNudge.for(@fiction)

      assert_equal ListingNudge::GONE_QUIET, nudge.kind
    end

    test 'plan reached takes priority over gone quiet' do
      @fiction.update!(last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)

      assert_equal ListingNudge::PLAN_REACHED, ListingNudge.for(@fiction).kind
    end

    test 'gone quiet after the matching plan-reached prompt was dismissed' do
      last_public = FictionListingProgress::STALE_AFTER.ago - 1.day
      @fiction.update!(last_chapter_at: last_public, listing_nudge_dismissals: { 'plan_reached' => 5 })

      assert_equal ListingNudge::GONE_QUIET, ListingNudge.for(@fiction).kind
    end

    test 'no gone quiet when last chapter is still within STALE_AFTER' do
      @fiction.update!(expected_chapters: nil, last_chapter_at: 1.day.ago)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no gone quiet when there is no public chapter yet' do
      @fiction.update!(expected_chapters: nil, last_chapter_at: nil)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no gone quiet when already complete' do
      @fiction.update!(
        expected_chapters: nil,
        last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day,
        completed_at: Time.current
      )

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no gone quiet when this silence was dismissed' do
      last_public = FictionListingProgress::STALE_AFTER.ago - 1.day
      @fiction.update!(
        expected_chapters: nil,
        last_chapter_at: last_public,
        listing_nudge_dismissals: { 'gone_quiet' => last_public.to_i }
      )

      assert_nil ListingNudge.for(@fiction)
    end

    test 'gone quiet returns after last_chapter_at changes' do
      old_public = FictionListingProgress::STALE_AFTER.ago - 30.days
      new_public = FictionListingProgress::STALE_AFTER.ago - 1.day
      @fiction.update!(
        expected_chapters: nil,
        last_chapter_at: new_public,
        listing_nudge_dismissals: { 'gone_quiet' => old_public.to_i }
      )

      assert_equal ListingNudge::GONE_QUIET, ListingNudge.for(@fiction).kind
    end

    test 'dismiss hides the current gone-quiet nudge' do
      last_public = FictionListingProgress::STALE_AFTER.ago - 1.day
      @fiction.update!(expected_chapters: nil, last_chapter_at: last_public)

      ListingNudge.new(@fiction).dismiss!

      assert_nil ListingNudge.for(@fiction.reload)
      assert_equal last_public.to_i, @fiction.listing_nudge_dismissals['gone_quiet']
    end

    test 'complete from gone quiet stamps completed_at' do
      @fiction.update!(expected_chapters: nil, last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)

      ListingNudge.new(@fiction).complete!

      assert_not_nil @fiction.reload.completed_at
      assert_nil ListingNudge.for(@fiction)
    end
  end
end
