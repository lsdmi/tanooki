# frozen_string_literal: true

require 'test_helper'

class FictionListingScopesTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @other = fictions(:two)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @other.scanlator_ids = @other.scanlators.ids
  end

  test 'finished is completed_at present' do
    @fiction.update!(completed_at: Time.current)

    assert_includes Fiction.finished, @fiction
    assert_not_includes Fiction.finished, @other
  end

  test 'live is recent last_chapter_at without complete' do
    @fiction.update!(chapter_count: 3, last_chapter_at: 1.day.ago, completed_at: nil)

    assert_includes Fiction.live, @fiction
    assert_not_includes Fiction.live, @other
  end

  test 'announced is a listing with no public chapter time' do
    @fiction.update!(chapter_count: 4, last_chapter_at: nil, completed_at: nil)

    assert_includes Fiction.announced, @fiction
    assert_not_includes Fiction.stale, @fiction
    assert_not_includes Fiction.live, @fiction
  end

  test 'stale is old last_chapter_at without complete' do
    @fiction.update!(chapter_count: 3, last_chapter_at: 91.days.ago, completed_at: nil)

    assert_includes Fiction.stale, @fiction
    assert_not_includes Fiction.live, @fiction
    assert_not_includes Fiction.finished, @fiction
  end
end
