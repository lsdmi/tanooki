# frozen_string_literal: true

require 'test_helper'

class FictionFormListingEditorialTest < ActiveSupport::TestCase
  def listing_form(fiction, **params)
    FictionForm.new(
      fiction: fiction,
      params: {
        title: fiction.title,
        author: fiction.author,
        description: fiction.description,
        scanlator_ids: [1],
        **params
      }
    )
  end

  test 'blank expected_chapters is stored as nil' do
    fiction = fictions(:one)

    assert listing_form(fiction, expected_chapters: '').save
    assert_nil fiction.reload.expected_chapters
  end

  test 'release finished stamps completed_at and clears a pause' do
    fiction = fictions(:one)
    fiction.update!(chapter_count: 2, paused_at: 1.day.ago)

    assert listing_form(fiction, release: 'finished').save
    assert_not_nil fiction.reload.completed_at
    assert_nil fiction.paused_at
  end

  test 'release ongoing clears both timestamps' do
    fiction = fictions(:one)
    fiction.update!(chapter_count: 2, completed_at: Time.current, paused_at: 1.day.ago)

    assert listing_form(fiction, release: 'ongoing').save

    fiction.reload

    assert_nil fiction.completed_at
    assert_nil fiction.paused_at
  end

  test 'release paused with no chapters is invalid' do
    fiction = fictions(:one)
    fiction.update!(chapter_count: 0, completed_at: Time.current)
    form = listing_form(fiction, release: 'paused')

    assert_not form.save
    assert_not_empty fiction.errors[:paused_at]
  end

  test 'release paused with no chapters does not persist' do
    fiction = fictions(:one)
    fiction.update!(chapter_count: 0, completed_at: Time.current)
    listing_form(fiction, release: 'paused').save

    fiction.reload

    assert_nil fiction.paused_at
    assert_not_nil fiction.completed_at
  end

  test 'release paused stamps paused_at when chapters exist' do
    fiction = fictions(:one)
    fiction.update!(chapter_count: 2, completed_at: Time.current)

    assert listing_form(fiction, release: 'paused').save

    fiction.reload

    assert_not_nil fiction.paused_at
    assert_nil fiction.completed_at
  end

  test 'rejects expected_chapters below live chapter_count' do
    fiction = fictions(:one)
    fiction.update!(chapter_count: 10)
    form = listing_form(fiction, expected_chapters: 3)

    assert_not form.save
    assert_not_empty fiction.errors[:expected_chapters]
  end
end
