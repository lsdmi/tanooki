# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressRecentInlineImagesJobTest < ActiveSupport::TestCase
    test 'enqueues compress jobs for chapters posted yesterday in production' do
      travel_to Time.zone.parse('2026-07-19 03:30:00') do
        yesterday_chapter = chapters(:one)
        yesterday_chapter.update_columns( # rubocop:disable Rails/SkipsModelValidations
          published_at: Time.zone.parse('2026-07-18 12:00'),
          created_at: Time.zone.parse('2026-07-10 12:00')
        )

        old_chapter = chapters(:two)
        old_chapter.update_columns( # rubocop:disable Rails/SkipsModelValidations
          published_at: Time.zone.parse('2026-07-16 12:00'),
          created_at: Time.zone.parse('2026-07-16 12:00')
        )

        other_chapter = chapters(:three)
        other_chapter.update_columns( # rubocop:disable Rails/SkipsModelValidations
          published_at: nil,
          created_at: Time.zone.parse('2026-07-16 12:00')
        )

        enqueued_chapter_ids = []

        Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
          CompressInlineImagesJob.stub(:perform_later, ->(chapter_id) { enqueued_chapter_ids << chapter_id }) do
            CompressRecentInlineImagesJob.new.perform(day: Date.parse('2026-07-19'))
          end
        end

        assert_equal [yesterday_chapter.id], enqueued_chapter_ids
        assert_not_includes enqueued_chapter_ids, old_chapter.id
      end
    end

    test 'does nothing outside production' do
      called = false

      CompressInlineImagesJob.stub(:perform_later, ->(*) { called = true }) do
        CompressRecentInlineImagesJob.new.perform
      end

      assert_not called
    end
  end
end
