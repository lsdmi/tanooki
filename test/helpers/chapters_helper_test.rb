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

  test 'chapter_list_sections groups chapters by volume' do
    fiction = fictions(:one)
    with_vol = Chapter.create!(
      fiction: fiction,
      user: users(:user_one),
      title: 'Vol chapter',
      number: 1,
      volume_number: 1,
      content: 'x' * 500,
      scanlator_ids: [scanlators(:one).id]
    )

    sections = chapter_list_sections(fiction.chapters.where(id: with_vol.id))

    assert_equal 1, sections.size
    assert_equal 'Том 1', sections.first[:title]
    assert_includes sections.first[:chapters], with_vol
  ensure
    with_vol&.destroy
  end

  test 'chapter_list_sections uses range groups for unnumbered chapters' do
    fiction = fictions(:one)
    without_vol = Chapter.create!(
      fiction: fiction,
      user: users(:user_one),
      title: 'Plain chapter',
      number: 2,
      volume_number: nil,
      content: 'y' * 500,
      scanlator_ids: [scanlators(:one).id]
    )

    sections = chapter_list_sections(fiction.chapters.where(id: without_vol.id))

    assert_equal 1, sections.size
    assert sections.first[:title].start_with?('Розділи ')
    assert_includes sections.first[:chapters], without_vol
  ensure
    without_vol&.destroy
  end

  test 'chapter_list_sections ignores inherited order when collecting volume numbers' do
    fiction = fictions(:one)
    ordered = fiction.chapters.order(number: :desc)

    assert_nothing_raised do
      chapter_list_sections(ordered)
    end
  end

  test 'chapter_list_sections uses only ranges when no volume numbers exist' do
    fiction = fictions(:one)
    chapter = Chapter.create!(
      fiction: fiction,
      user: users(:user_one),
      title: 'Range chapter',
      number: 50,
      volume_number: nil,
      content: 'z' * 500,
      scanlator_ids: [scanlators(:one).id]
    )

    sections = chapter_list_sections(fiction.chapters.where(id: chapter.id))

    assert_equal 1, sections.size
    assert_equal 'Розділи 1-100', sections.first[:title]
  ensure
    chapter&.destroy
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
