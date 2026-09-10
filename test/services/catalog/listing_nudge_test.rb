# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.update!(chapter_count: 5, expected_chapters: 5, completed_at: nil, listing_nudge_dismissals: {})
    end

    test 'plan reached when live count matches expected and listing is not complete' do
      nudge = ListingNudge.for(@fiction)

      assert_equal ListingNudge::PLAN_REACHED, nudge.kind
      assert_equal 5, nudge.chapter_count
    end

    test 'no nudge when expected is blank' do
      @fiction.update!(expected_chapters: nil)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no nudge when live count differs from expected' do
      @fiction.update!(chapter_count: 4)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no nudge when already complete' do
      @fiction.update!(completed_at: Time.current)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no nudge when this plan was dismissed' do
      @fiction.update!(listing_nudge_dismissals: { 'plan_reached' => 5 })

      assert_nil ListingNudge.for(@fiction)
    end

    test 'nudge returns after the expected plan changes' do
      @fiction.update!(listing_nudge_dismissals: { 'plan_reached' => 5 }, expected_chapters: 8,
                       chapter_count: 8)

      nudge = ListingNudge.for(@fiction)

      assert_equal ListingNudge::PLAN_REACHED, nudge.kind
      assert_equal 8, nudge.chapter_count
    end

    test 'complete stamps completed_at' do
      ListingNudge.new(@fiction).complete!

      assert_not_nil @fiction.reload.completed_at
      assert_nil ListingNudge.for(@fiction)
    end

    test 'dismiss hides the current plan-reached nudge' do
      ListingNudge.new(@fiction).dismiss!

      assert_nil ListingNudge.for(@fiction.reload)
      assert_equal 5, @fiction.listing_nudge_dismissals['plan_reached']
    end
  end
end
