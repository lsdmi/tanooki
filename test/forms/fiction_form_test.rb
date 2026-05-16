# frozen_string_literal: true

require 'test_helper'

class FictionFormTest < ActiveSupport::TestCase
  test 'keeps scanlator_ids and genre_ids from params when save fails' do
    fiction = fictions(:one)
    submitted_scanlator_ids = %w[1 2]
    submitted_genre_ids = [genres(:one).id]

    form = FictionForm.new(
      fiction: fiction,
      params: {
        title: '',
        author: fiction.author,
        description: fiction.description,
        total_chapters: fiction.total_chapters,
        scanlator_ids: submitted_scanlator_ids,
        genre_ids: submitted_genre_ids
      }
    )

    assert_not form.save
    assert_equal submitted_scanlator_ids, fiction.scanlator_ids.map(&:to_s)
    assert_equal submitted_genre_ids.map(&:to_s), fiction.genre_ids.map(&:to_s)
  end
end
