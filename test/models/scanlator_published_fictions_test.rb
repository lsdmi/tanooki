# frozen_string_literal: true

require 'test_helper'

class ScanlatorPublishedFictionsTest < ActiveSupport::TestCase
  test 'fictions_with_published_chapters omits draft-only fictions' do
    scanlator = scanlators(:one)
    fiction = fictions(:one)
    fiction.chapters.find_each { |chapter| chapter.update!(status: :draft, scanlator_ids: chapter.scanlators.ids) }

    assert_not_includes scanlator.fictions_with_published_chapters.map(&:id), fiction.id
  end
end
