# frozen_string_literal: true

require 'test_helper'

class LibraryHelperTest < ActionView::TestCase
  include LibraryHelper

  setup do
    @fiction = fictions(:one)
    @chapter_one = chapters(:one)
    @chapter_two = chapters(:two)
  end

  test 'ordered_chapters returns ordered chapters' do
    assert_equal [@chapter_one, @chapter_two], ordered_chapters(@fiction)
  end

  test 'chapters_size returns size of ordered_chapters array' do
    assert_equal 2, chapters_size(@fiction)
  end
end
