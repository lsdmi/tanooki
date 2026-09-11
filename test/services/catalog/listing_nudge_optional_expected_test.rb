# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeOptionalExpectedTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.update!(
        chapter_count: ListingNudge::OPTIONAL_EXPECTED_AFTER,
        expected_chapters: nil,
        completed_at: nil,
        last_chapter_at: 1.day.ago,
        listing_nudge_dismissals: {}
      )
    end

    test 'soft asks when live count is high and expected is blank' do
      nudge = ListingNudge.for(@fiction)

      assert_equal ListingNudge::OPTIONAL_EXPECTED, nudge.kind
      assert_equal ListingNudge::OPTIONAL_EXPECTED_AFTER, nudge.chapter_count
    end

    test 'no soft ask below the threshold' do
      @fiction.update!(chapter_count: ListingNudge::OPTIONAL_EXPECTED_AFTER - 1)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no soft ask when expected is already set' do
      @fiction.update!(expected_chapters: 40)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no soft ask when already complete' do
      @fiction.update!(completed_at: Time.current)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'gone quiet takes priority over soft ask' do
      @fiction.update!(last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)

      assert_equal ListingNudge::GONE_QUIET, ListingNudge.for(@fiction).kind
    end

    test 'no soft ask when this count was dismissed' do
      @fiction.update!(listing_nudge_dismissals: { 'optional_expected' => @fiction.chapter_count })

      assert_nil ListingNudge.for(@fiction)
    end

    test 'soft ask returns after another chapter is posted' do
      @fiction.update!(
        listing_nudge_dismissals: { 'optional_expected' => @fiction.chapter_count },
        chapter_count: @fiction.chapter_count + 1
      )

      assert_equal ListingNudge::OPTIONAL_EXPECTED, ListingNudge.for(@fiction).kind
    end

    test 'dismiss hides the soft ask without writing expected' do
      ListingNudge.new(@fiction).dismiss!

      @fiction.reload

      assert_nil ListingNudge.for(@fiction)
      assert_nil @fiction.expected_chapters
      assert_equal ListingNudge::OPTIONAL_EXPECTED_AFTER, @fiction.listing_nudge_dismissals['optional_expected']
    end
  end
end
