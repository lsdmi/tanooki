# frozen_string_literal: true

require 'test_helper'

module Catalog
  class RefreshChapterStatsJobTest < ActiveJob::TestCase
    setup do
      @fiction = fictions(:eighteen)
      @release_at = 3.hours.from_now.change(usec: 0)
      Chapters::Persist.call(
        chapter: Chapter.new(user: users(:user_one)),
        attributes: { content: 'x' * 500, fiction_id: @fiction.id, number: 1, published_at: @release_at,
                      scanlator_ids: [scanlators(:one).id.to_s], title: 'Scheduled' },
        intent: 'publish',
        user: users(:user_one)
      )
    end

    test 'a fiction whose only chapter is scheduled stays announced until it goes live' do
      @fiction.reload

      assert_equal 1, @fiction.chapter_count
      assert_equal :announced, @fiction.listing_state
    end

    test 'running at release time records the chapter and the fiction is ongoing' do
      travel_to @release_at + 1.second do
        RefreshChapterStatsJob.perform_now(@fiction.id)

        assert_in_delta @release_at, @fiction.reload.last_chapter_at, 1.second
        assert_equal :ongoing, @fiction.listing_state
      end
    end

    test 'a deleted fiction is discarded' do
      assert_nothing_raised { RefreshChapterStatsJob.perform_now(0) }
    end
  end
end
