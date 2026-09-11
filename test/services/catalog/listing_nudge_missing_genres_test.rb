# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeMissingGenresTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.genres = []
      @fiction.update!(
        chapter_count: 3,
        expected_chapters: 20,
        completed_at: nil,
        adult_content: false,
        last_chapter_at: 1.day.ago,
        listing_nudge_dismissals: {}
      )
    end

    test 'asks to add a genre when chapters exist and genres are empty' do
      assert_equal ListingNudge::MISSING_GENRES, ListingNudge.for(@fiction).kind
    end

    test 'no missing-genres nudge without chapters' do
      @fiction.update!(chapter_count: 0, last_chapter_at: nil)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no missing-genres nudge when genres are present' do
      @fiction.genres = [genres(:one)]

      assert_nil ListingNudge.for(@fiction)
    end

    test 'gone quiet takes priority over missing genres' do
      @fiction.update!(last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)

      assert_equal ListingNudge::GONE_QUIET, ListingNudge.for(@fiction).kind
    end

    test 'missing genres takes priority over optional expected' do
      @fiction.update!(expected_chapters: nil, chapter_count: ListingNudge::OPTIONAL_EXPECTED_AFTER)

      assert_equal ListingNudge::MISSING_GENRES, ListingNudge.for(@fiction).kind
    end

    test 'no missing-genres nudge when this count was dismissed' do
      @fiction.update!(listing_nudge_dismissals: { 'missing_genres' => 3 })

      assert_nil ListingNudge.for(@fiction)
    end

    test 'missing-genres nudge returns after another chapter is posted' do
      @fiction.update!(listing_nudge_dismissals: { 'missing_genres' => 3 }, chapter_count: 4)

      assert_equal ListingNudge::MISSING_GENRES, ListingNudge.for(@fiction).kind
    end

    test 'dismiss hides the missing-genres nudge without adding genres' do
      ListingNudge.new(@fiction).dismiss!

      @fiction.reload

      assert_nil ListingNudge.for(@fiction)
      assert_empty @fiction.genres
      assert_equal 3, @fiction.listing_nudge_dismissals['missing_genres']
    end
  end
end
