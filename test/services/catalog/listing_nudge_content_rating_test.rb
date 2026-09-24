# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeContentRatingTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @bl = Genre.find_or_create_by!(slug: 'bl') do |genre|
        genre.name = 'БЛ'
        genre.description = 'Тестовий BL-жанр для nudges.'
      end
      @fiction.genres = [@bl]
      @fiction.update!(
        chapter_count: 3,
        expected_chapters: 20,
        completed_at: nil,
        content_rating: :everyone,
        last_chapter_at: 1.day.ago,
        listing_nudge_dismissals: {}
      )
    end

    test 'asks to set rating when explicit genres are present and rating is everyone' do
      assert_equal ListingNudge::CONTENT_RATING, ListingNudge.for(@fiction).kind
    end

    test 'does not auto-set content_rating' do
      ListingNudge.for(@fiction)

      assert_predicate @fiction.reload, :content_rating_everyone?
    end

    test 'no content rating nudge without explicit genres' do
      @fiction.genres = [genres(:one)]

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no content rating nudge when already sixteen' do
      @fiction.update!(content_rating: :sixteen)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no content rating nudge when already eighteen' do
      @fiction.update!(content_rating: :eighteen)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'gone quiet takes priority over content rating' do
      @fiction.update!(last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)

      assert_equal ListingNudge::GONE_QUIET, ListingNudge.for(@fiction).kind
    end

    test 'content rating takes priority over optional expected' do
      @fiction.update!(expected_chapters: nil, chapter_count: ListingNudge::OPTIONAL_EXPECTED_AFTER)

      assert_equal ListingNudge::CONTENT_RATING, ListingNudge.for(@fiction).kind
    end

    test 'no content rating nudge when this explicit set was dismissed' do
      @fiction.update!(listing_nudge_dismissals: { 'content_rating' => 'bl' })

      assert_nil ListingNudge.for(@fiction)
    end

    test 'content rating nudge returns after another explicit genre is added' do
      harem = Genre.find_or_create_by!(slug: 'harem') do |genre|
        genre.name = 'Гарем'
        genre.description = 'Тестовий гарем-жанр для nudges.'
      end
      @fiction.update!(listing_nudge_dismissals: { 'content_rating' => 'bl' })
      @fiction.genres = [@bl, harem]

      assert_equal ListingNudge::CONTENT_RATING, ListingNudge.for(@fiction).kind
    end

    test 'mark sixteen sets the rating and clears the nudge' do
      ListingNudge.new(@fiction).mark_sixteen!

      assert_predicate @fiction.reload, :content_rating_sixteen?
      assert_nil ListingNudge.for(@fiction)
    end

    test 'mark eighteen sets the rating and clears the nudge' do
      ListingNudge.new(@fiction).mark_eighteen!

      assert_predicate @fiction.reload, :content_rating_eighteen?
      assert_nil ListingNudge.for(@fiction)
    end

    test 'dismiss hides the nudge without setting a rating' do
      ListingNudge.new(@fiction).dismiss!

      @fiction.reload

      assert_nil ListingNudge.for(@fiction)
      assert_predicate @fiction, :content_rating_everyone?
      assert_equal 'bl', @fiction.listing_nudge_dismissals['content_rating']
    end
  end
end
