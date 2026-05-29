# frozen_string_literal: true

require 'test_helper'

module Library
  class ChapterCatalogTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @chapter_one = chapters(:one)
      @chapter_two = chapters(:two)
    end

    test 'ordered_chapters returns ordered chapters' do
      assert_equal [@chapter_one, @chapter_two], ChapterCatalog.ordered_chapters(@fiction).to_a
    end

    test 'chapters_size returns size of ordered chapters array' do
      assert_equal 2, ChapterCatalog.chapters_size(@fiction)
    end

    test 'ordered_chapters for guest excludes chapters not yet visible to everyone' do
      travel_to Time.zone.parse('2026-06-01 12:00') do
        update_chapter_schedule!(@chapter_one, published_at: 1.day.from_now)
        visible = ChapterCatalog.ordered_chapters(@fiction, viewer: nil).to_a

        assert_includes visible, @chapter_two
        assert_not_includes visible, @chapter_one
      ensure
        update_chapter_schedule!(@chapter_one, published_at: nil)
      end
    end

    test 'fiction_has_listable_chapters? is false when all chapters are future-published for guest' do
      travel_to Time.zone.parse('2026-06-01 12:00') do
        update_chapter_schedule!(@chapter_one, published_at: 1.day.from_now)
        update_chapter_schedule!(@chapter_two, published_at: 1.day.from_now)

        assert_not ChapterCatalog.fiction_has_listable_chapters?(@fiction, nil)
      ensure
        update_chapter_schedule!(@chapter_one, published_at: nil)
        update_chapter_schedule!(@chapter_two, published_at: nil)
      end
    end

    private

    def update_chapter_schedule!(chapter, published_at:)
      chapter.update!(published_at:, scanlator_ids: chapter.scanlators.ids)
    end
  end
end
