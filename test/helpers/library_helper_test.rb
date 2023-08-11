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
end
