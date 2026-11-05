# frozen_string_literal: true

module Contests
  # Every 15 minutes: lock entries for contests whose submission window has closed.
  # P2 will also run ReaderStats here.
  class TickJob < ApplicationJob
    queue_as :default

    def perform
      due_contests.find_each do |contest|
        LockEntries.call(contest:)
      rescue LockEntries::Error => e
        Rails.logger.info("[Contests::TickJob] contest=#{contest.id} skip=#{e.message}")
      end
    end

    private

    def due_contests
      Contest.where(cancelled_at: nil)
             .where(submissions_close_at: ..Time.current)
             .where(results_published_at: nil)
             .where(id: ContestEntry.accepted.where(locked_snapshot: nil).select(:contest_id))
    end
  end
end
