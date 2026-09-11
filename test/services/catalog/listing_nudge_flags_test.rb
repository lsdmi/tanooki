# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeFlagsTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.update!(
        chapter_count: 5,
        expected_chapters: 5,
        completed_at: nil,
        listing_nudge_dismissals: {}
      )
    end

    test 'maps fictions with a current nudge' do
      flags = ListingNudgeFlags.for_fictions([@fiction])

      assert_equal ListingNudge::PLAN_REACHED, flags[@fiction.id].kind
      assert_match 'Схоже, ви виклали всі 5 розділів', flags[@fiction.id].body
    end

    test 'skips fictions without a nudge' do
      @fiction.update!(expected_chapters: 8)

      assert_empty ListingNudgeFlags.for_fictions([@fiction])
    end

    test 'skips dismissed nudges' do
      @fiction.update!(listing_nudge_dismissals: { 'plan_reached' => 5 })

      assert_empty ListingNudgeFlags.for_fictions([@fiction])
    end
  end
end
