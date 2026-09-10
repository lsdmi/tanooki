# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeStalePlanTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.update!(chapter_count: 8, expected_chapters: 5, completed_at: nil, listing_nudge_dismissals: {})
    end

    test 'stale plan when live count overran expected' do
      nudge = ListingNudge.for(@fiction)

      assert_equal ListingNudge::STALE_PLAN, nudge.kind
      assert_equal 8, nudge.chapter_count
      assert_equal 5, nudge.expected_chapters
    end

    test 'plan reached takes priority when counts match' do
      @fiction.update!(chapter_count: 5)

      assert_equal ListingNudge::PLAN_REACHED, ListingNudge.for(@fiction).kind
    end

    test 'stale plan takes priority over gone quiet' do
      @fiction.update!(last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)

      assert_equal ListingNudge::STALE_PLAN, ListingNudge.for(@fiction).kind
    end

    test 'posted after complete takes priority over stale plan' do
      @fiction.update!(completed_at: 2.days.ago, last_chapter_at: 1.day.ago)

      assert_equal ListingNudge::POSTED_AFTER_COMPLETE, ListingNudge.for(@fiction).kind
    end

    test 'no stale plan when expected is blank' do
      @fiction.update!(expected_chapters: nil)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no stale plan when live count is below expected' do
      @fiction.update!(chapter_count: 4)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no stale plan when this overrun was dismissed' do
      @fiction.update!(listing_nudge_dismissals: { 'stale_plan' => 8 })

      assert_nil ListingNudge.for(@fiction)
    end

    test 'stale plan returns after another chapter is posted' do
      @fiction.update!(listing_nudge_dismissals: { 'stale_plan' => 8 }, chapter_count: 9)

      assert_equal ListingNudge::STALE_PLAN, ListingNudge.for(@fiction).kind
    end

    test 'raise expected matches live count and does not immediately ask to complete' do
      ListingNudge.new(@fiction).raise_expected!

      @fiction.reload

      assert_equal 8, @fiction.expected_chapters
      assert_nil ListingNudge.for(@fiction)
      assert_equal 8, @fiction.listing_nudge_dismissals['plan_reached']
    end

    test 'clear expected removes the plan' do
      ListingNudge.new(@fiction).clear_expected!

      @fiction.reload

      assert_nil @fiction.expected_chapters
      assert_nil ListingNudge.for(@fiction)
    end

    test 'dismiss hides the current stale-plan nudge' do
      ListingNudge.new(@fiction).dismiss!

      assert_nil ListingNudge.for(@fiction.reload)
      assert_equal 8, @fiction.listing_nudge_dismissals['stale_plan']
      assert_equal 5, @fiction.expected_chapters
    end
  end
end
