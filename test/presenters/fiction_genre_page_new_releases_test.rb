# frozen_string_literal: true

require 'test_helper'

class FictionGenrePageNewReleasesTest < ActiveSupport::TestCase
  setup do
    @skeleton = FictionGenrePageSkeleton.new(genres(:one))
    @fiction = fictions(:one)
  end

  test 'genre thumb cards show only the live chapter count' do
    @fiction.chapter_count = 307
    @fiction.expected_chapters = 400
    @fiction.completed_at = Time.current

    card = @skeleton.genre_thumb_card_locals(@fiction, accent_index: 0)

    assert_equal 307, card[:chapters]
    assert_equal '307 Розділи', card[:chapters_label]
    assert_equal '307 розд.', card[:chapters_label_short]
  end

  test 'genre thumb cards expose full and short listing status labels' do
    @fiction.chapter_count = 307
    @fiction.expected_chapters = 400
    @fiction.completed_at = Time.current

    card = @skeleton.genre_thumb_card_locals(@fiction, accent_index: 0)

    assert_equal 'Завершено', card[:status]
    assert_equal 'Заверш.', card[:status_short]
  end

  test 'a licensed work shows the licensed label instead of its listing state' do
    @fiction.assign_attributes(chapter_count: 3, last_chapter_at: 4.months.ago, licensed_at: 1.day.ago)

    card = @skeleton.genre_thumb_card_locals(@fiction, accent_index: 0)

    assert_equal %w[Ліцензовано Ліценз.], card.values_at(:status, :status_short)
  end
end
