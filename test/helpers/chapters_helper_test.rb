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
end
