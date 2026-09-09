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
    assert_equal 'Завершено', card[:status]
  end
end
