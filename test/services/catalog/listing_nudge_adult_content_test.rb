# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ListingNudgeAdultContentTest < ActiveSupport::TestCase
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
        adult_content: false,
        last_chapter_at: 1.day.ago,
        listing_nudge_dismissals: {}
      )
    end

    test 'asks to mark adult when explicit genres are present and adult_content is false' do
      assert_equal ListingNudge::ADULT_CONTENT, ListingNudge.for(@fiction).kind
    end

    test 'does not auto-set adult_content' do
      ListingNudge.for(@fiction)

      assert_not @fiction.reload.adult_content?
    end

    test 'no adult nudge without explicit genres' do
      @fiction.genres = [genres(:one)]

      assert_nil ListingNudge.for(@fiction)
    end

    test 'no adult nudge when adult_content is already true' do
      @fiction.update!(adult_content: true)

      assert_nil ListingNudge.for(@fiction)
    end

    test 'gone quiet takes priority over adult content' do
      @fiction.update!(last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)

      assert_equal ListingNudge::GONE_QUIET, ListingNudge.for(@fiction).kind
    end

    test 'adult content takes priority over optional expected' do
      @fiction.update!(expected_chapters: nil, chapter_count: ListingNudge::OPTIONAL_EXPECTED_AFTER)

      assert_equal ListingNudge::ADULT_CONTENT, ListingNudge.for(@fiction).kind
    end

    test 'no adult nudge when this explicit set was dismissed' do
      @fiction.update!(listing_nudge_dismissals: { 'adult_content' => 'bl' })

      assert_nil ListingNudge.for(@fiction)
    end

    test 'adult nudge returns after another explicit genre is added' do
      harem = Genre.find_or_create_by!(slug: 'harem') do |genre|
        genre.name = 'Гарем'
        genre.description = 'Тестовий гарем-жанр для nudges.'
      end
      @fiction.update!(listing_nudge_dismissals: { 'adult_content' => 'bl' })
      @fiction.genres = [@bl, harem]

      assert_equal ListingNudge::ADULT_CONTENT, ListingNudge.for(@fiction).kind
    end

    test 'mark adult sets the flag and clears the nudge' do
      ListingNudge.new(@fiction).mark_adult!

      assert_predicate @fiction.reload, :adult_content?
      assert_nil ListingNudge.for(@fiction)
    end

    test 'dismiss hides the adult nudge without setting the flag' do
      ListingNudge.new(@fiction).dismiss!

      @fiction.reload

      assert_nil ListingNudge.for(@fiction)
      assert_not @fiction.adult_content?
      assert_equal 'bl', @fiction.listing_nudge_dismissals['adult_content']
    end
  end
end
