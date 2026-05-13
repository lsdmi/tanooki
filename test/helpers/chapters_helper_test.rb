# frozen_string_literal: true

require 'test_helper'

class ChaptersHelperTest < ActionView::TestCase
  include ChaptersHelper

  test 'chapters_allow_epub_download? is true when all chapters have convertable scanlators' do
    assert chapters_allow_epub_download?([chapters(:one), chapters(:two)])
  end

  test 'chapters_allow_epub_download? is false for an empty list' do
    assert_not chapters_allow_epub_download?([])
  end

  test 'chapters_allow_epub_download? is false when any scanlator is not convertable' do
    c1 = chapters(:one)
    sl = scanlators(:one)
    sl.convertable = false
    sl.save(validate: false)

    assert_not chapters_allow_epub_download?([c1])
  ensure
    sl = scanlators(:one)
    sl.convertable = true
    sl.save(validate: false)
  end

  test 'chapter_epub_download_allowed? is true when all scanlators are convertable' do
    assert chapter_epub_download_allowed?(chapters(:one))
  end

  test 'chapter_epub_download_allowed? is false when a scanlator is not convertable' do
    c1 = chapters(:one)
    sl = scanlators(:one)
    sl.convertable = false
    sl.save(validate: false)

    assert_not chapter_epub_download_allowed?(c1)
  ensure
    sl = scanlators(:one)
    sl.convertable = true
    sl.save(validate: false)
  end

  test "volume_number_integer returns 'NA' when nil is passed" do
    assert_equal 'NA', volume_number_integer(nil)
  end

  test 'volume_number_integer returns 0 when 0 is passed' do
    assert_equal 0, volume_number_integer(0)
  end

  test 'volume_number_integer returns the correct value when a number is passed' do
    assert_equal 500, volume_number_integer(5)
    assert_equal 0, volume_number_integer(0.0)
    assert_equal 100, volume_number_integer(1)
  end
end
