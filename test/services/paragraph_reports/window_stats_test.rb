# frozen_string_literal: true

require 'test_helper'

module ParagraphReports
  class WindowStatsTest < ActiveSupport::TestCase
    setup do
      @digest = 'w' * ParagraphReport::DIGEST_LENGTH
      travel_to Time.zone.parse('2026-11-14 12:00:00') do
        ParagraphReport.create!(
          user: users(:user_two), chapter: chapters(:one), block_index: 0,
          quote: 'Свіжий open', digest: @digest
        )
        ParagraphReport.create!(
          user: users(:user_two), chapter: chapters(:one), block_index: 1,
          quote: 'Свіжий fixed', digest: @digest, status: :fixed,
          resolved_at: Time.current, resolved_by: users(:user_one)
        )
        ParagraphReport.create!(
          user: users(:user_two), chapter: chapters(:one), block_index: 2,
          quote: 'Старий fixed', digest: @digest, status: :fixed,
          created_at: 40.days.ago, resolved_at: 40.days.ago, resolved_by: users(:user_one)
        )
      end
    end

    test 'summarizes created and resolved counts for 28 days' do
      travel_to Time.zone.parse('2026-11-14 12:00:00') do
        stats = WindowStats.build

        assert_equal(
          { window_days: 28, created_total: 2, created_open: 1, created_fixed: 1, created_dismissed: 0,
            fixed_in_window: 1, dismissed_in_window: 0, open_now: 1 },
          stats.to_h
        )
      end
    end
  end
end
