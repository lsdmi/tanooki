# frozen_string_literal: true

require 'test_helper'

class LibraryHelperTest < ActionView::TestCase
  include LibraryHelper

  setup do
    @fiction = fictions(:one)
    @chapter_one = chapters(:one)
    @chapter_two = chapters(:two)
    @chapter_three = chapters(:three)
  end

  test 'ordered_chapters returns ordered chapters' do
    assert_equal [@chapter_one, @chapter_two], ordered_chapters(@fiction)
  end

  test 'chapters_size returns size of ordered_chapters array' do
    assert_equal 2, chapters_size(@fiction)
  end

  test 'ordered_chapters for guest excludes chapters not yet visible to everyone' do
    travel_to Time.zone.parse('2026-06-01 12:00') do
      update_chapter_schedule!(@chapter_one, published_at: 1.day.from_now)
      visible = ordered_chapters(@fiction, viewer: nil).to_a

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

      assert_not fiction_has_listable_chapters?(@fiction, nil)
    ensure
      update_chapter_schedule!(@chapter_one, published_at: nil)
      update_chapter_schedule!(@chapter_two, published_at: nil)
    end
  end

  test 'fiction_epub_download_support is all when every listable chapter allows epub' do
    assert_equal :all, fiction_epub_download_support(@fiction, viewer: nil)
  end

  test 'fiction_epub_download_support is none when no listable chapter allows epub' do
    sl = scanlators(:one)
    sl.convertable = false
    sl.save(validate: false)

    assert_equal :none, fiction_epub_download_support(@fiction, viewer: nil)
  ensure
    sl = scanlators(:one)
    sl.convertable = true
    sl.save(validate: false)
  end

  test 'fiction_epub_download_support is mixed when some chapters allow epub and some do not' do
    s2 = scanlators(:two)
    s2.convertable = false
    s2.save(validate: false)
    @chapter_two.chapter_scanlators.destroy_all
    ChapterScanlatorsManager.new([s2.id.to_s], @chapter_two.reload).operate

    assert_equal :mixed, fiction_epub_download_support(@fiction, viewer: nil)
  ensure
    s2 = scanlators(:two)
    s2.convertable = true
    s2.save(validate: false)
    @chapter_two.reload.chapter_scanlators.destroy_all
    ChapterScanlatorsManager.new([scanlators(:one).id.to_s], @chapter_two).operate
  end

  private

  # Chapter validates virtual scanlator_ids on every save; pass existing teams from fixtures.
  def update_chapter_schedule!(chapter, published_at:)
    chapter.update!(published_at:, scanlator_ids: chapter.scanlators.ids)
  end
end
