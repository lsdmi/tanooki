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

  test 'checking complete stamps completed_at' do
    fiction = fictions(:one)

    assert listing_form(fiction, expected_chapters: fiction.expected_chapters, complete: '1').save
    assert_not_nil fiction.reload.completed_at
  end

  test 'unchecking complete clears completed_at' do
    fiction = fictions(:one)
    fiction.update!(completed_at: Time.current)

    assert listing_form(fiction, expected_chapters: fiction.expected_chapters, complete: '0').save
    assert_nil fiction.reload.completed_at
  end

  test 'rejects expected_chapters below live chapter_count' do
    fiction = fictions(:one)
    fiction.update!(chapter_count: 10)
    form = listing_form(fiction, expected_chapters: 3)

    assert_not form.save
    assert_not_empty fiction.errors[:expected_chapters]
  end
end
