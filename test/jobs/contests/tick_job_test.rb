# frozen_string_literal: true

require 'test_helper'

module Contests
  class TickJobTest < ActiveSupport::TestCase
    setup do
      @contest = contests(:submissions)
      @entry = contest_entries(:accepted)
      @entry.fiction.contest_entries.where.not(id: @entry.id).delete_all
    end

    test 'locks accepted entries after the deadline' do
      travel_to @contest.submissions_close_at + 1.minute do
        TickJob.perform_now
      end

      assert_predicate @entry.reload.locked_snapshot, :present?
      assert_includes %w[qualified incomplete], @entry.status
    end

    test 'does nothing while submissions are open' do
      TickJob.perform_now

      assert_nil @entry.reload.locked_snapshot
      assert_predicate @entry, :accepted?
    end

    test 'skips contests with published results' do
      @contest.update!(
        results_published_at: Time.current,
        judging_close_at: @contest.submissions_close_at + 1.week
      )

      travel_to @contest.submissions_close_at + 1.minute do
        TickJob.perform_now
      end

      assert_nil @entry.reload.locked_snapshot
    end
  end
end
