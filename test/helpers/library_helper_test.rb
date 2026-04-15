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

  test 'next_chapter_index returns correct index for a chapter within the list' do
    chapters = [@chapter_one, @chapter_two, @chapter_three]
    assert_equal 1, next_chapter_index(chapters, @chapter_two)
  end

  test 'next_chapter_index returns -1 for the last chapter in the list' do
    chapters = [@chapter_one, @chapter_two, @chapter_three]
    assert_equal 2, next_chapter_index(chapters, @chapter_three)
  end

  test 'ordered_chapters for guest excludes chapters not yet visible to everyone' do
    travel_to Time.zone.parse('2026-06-01 12:00') do
      @chapter_one.update_columns(published_at: 1.day.from_now)
      visible = ordered_chapters(@fiction, viewer: nil).to_a
      assert_includes visible, @chapter_two
      assert_not_includes visible, @chapter_one
    ensure
      @chapter_one.update_columns(published_at: nil)
    end
  end

  test 'fiction_has_listable_chapters? is false when all chapters are future-published for guest' do
    travel_to Time.zone.parse('2026-06-01 12:00') do
      @chapter_one.update_columns(published_at: 1.day.from_now)
      @chapter_two.update_columns(published_at: 1.day.from_now)
      assert_not fiction_has_listable_chapters?(@fiction, nil)
    ensure
      @chapter_one.update_columns(published_at: nil)
      @chapter_two.update_columns(published_at: nil)
    end
  end
end
