# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgePostedAfterCompleteTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.update!(
        chapter_count: 6,
        expected_chapters: 10,
        completed_at: 2.days.ago,
        last_chapter_at: 1.day.ago,
        listing_nudge_dismissals: {}
      )
    end

    test 'asks to clear complete when a chapter went public after completed_at' do
      nudge = ListingNudge.for(@fiction)

      assert_equal ListingNudge::POSTED_AFTER_COMPLETE, nudge.kind
    end

    test 'does not auto-clear completed_at' do
      ListingNudge.for(@fiction)

      assert_not_nil @fiction.reload.completed_at
    end

    test 'no nudge when last public chapter is older than completed_at' do
      @fiction.update!(last_chapter_at: 3.days.ago)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no nudge when listing is not complete' do
      @fiction.update!(completed_at: nil)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no nudge when this extra chapter was dismissed' do
      @fiction.update!(listing_nudge_dismissals: { 'posted_after_complete' => @fiction.last_chapter_at.to_i })

      assert_nil ListingNudge.for(@fiction)
    end

    test 'nudge returns after another chapter is posted' do
      old_public = @fiction.last_chapter_at
      @fiction.update!(
        listing_nudge_dismissals: { 'posted_after_complete' => old_public.to_i },
        last_chapter_at: Time.current
      )

      assert_equal ListingNudge::POSTED_AFTER_COMPLETE, ListingNudge.for(@fiction).kind
    end

    test 'reopen clears completed_at and does not stamp it again' do
      ListingNudge.new(@fiction).reopen!

      assert_nil @fiction.reload.completed_at
      assert_nil ListingNudge.for(@fiction)
    end

    test 'dismiss hides the current posted-after-complete nudge' do
      last_public = @fiction.last_chapter_at

      ListingNudge.new(@fiction).dismiss!

      assert_nil ListingNudge.for(@fiction.reload)
      assert_equal last_public.to_i, @fiction.listing_nudge_dismissals['posted_after_complete']
      assert_not_nil @fiction.completed_at
    end
  end
end
