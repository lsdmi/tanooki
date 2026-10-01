# frozen_string_literal: true

require 'test_helper'

module Chapters
  class PersistReleaseRefreshTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @chapter = Chapter.new(user: @user)
    end

    test 'a scheduled chapter queues a stats refresh for the fiction at its release time' do
      scheduled = 2.days.from_now.change(usec: 0)

      assert_difference -> { refresh_jobs.count } do
        publish(published_at: scheduled)
      end
      assert_in_delta scheduled, refresh_jobs.last.scheduled_at, 1.second
      assert_equal [@fiction.id], refresh_jobs.last.arguments['arguments']
    end

    test 'a chapter published now queues no release refresh' do
      assert_no_difference -> { refresh_jobs.count } do
        publish(published_at: nil)
      end
    end

    private

    def publish(published_at:)
      Persist.call(
        chapter: @chapter,
        attributes: { content: 'x' * 500, fiction_id: @fiction.id, number: 88, published_at:,
                      scanlator_ids: [scanlators(:one).id.to_s], title: 'Persist chapter' },
        intent: 'publish',
        user: @user
      )
    end

    def refresh_jobs
      SolidQueue::Job.where(class_name: 'Catalog::RefreshChapterStatsJob')
    end
  end
end
