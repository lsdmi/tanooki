# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerListingStatsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @chapter = chapters(:one)
  end

  test 'creating a chapter with a new number raises chapter_count' do
    post chapters_url, params: {
      chapter: {
        content: @chapter.content,
        fiction_id: @chapter.fiction_id,
        number: 3,
        scanlator_ids: [1],
        title: @chapter.title
      }
    }

    assert_equal 3, @chapter.fiction.reload.chapter_count
  end

  test 'creating a duplicate integer number keeps one slot in chapter_count' do
    post chapters_url, params: {
      chapter: {
        content: @chapter.content,
        fiction_id: @chapter.fiction_id,
        number: 1,
        scanlator_ids: [1],
        title: @chapter.title
      }
    }

    assert_equal 2, @chapter.fiction.reload.chapter_count
  end

  test 'updating published_at refreshes last_chapter_at' do
    scheduled = 2.days.from_now.change(usec: 0)
    patch chapter_url(@chapter), params: {
      chapter: {
        content: @chapter.content,
        fiction_id: @chapter.fiction_id,
        number: @chapter.number,
        scanlator_ids: [1],
        title: @chapter.title,
        published_at_date: scheduled.to_date.iso8601,
        published_at_time: scheduled.strftime('%H:%M:%S')
      }
    }

    assert_equal scheduled, @chapter.fiction.reload.last_chapter_at
  end
end
