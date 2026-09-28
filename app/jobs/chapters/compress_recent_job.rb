# frozen_string_literal: true

module Chapters
  # Nightly: compress inline images in chapters posted yesterday (config/recurring.yml).
  class CompressRecentJob < ApplicationJob
    # Rewriting bodies above this took the job container down (2026-08); the backfill handles them.
    MAX_BODY_BYTES = 4.megabytes

    queue_as :heavy

    def perform
      result = CompressRecent.call(max_body_bytes: MAX_BODY_BYTES)
      log_summary(result)
      raise BatchErrors, "#{result.errors.size} chapters failed: #{result.errors.first(5)}" if result.errors.any?
    end

    private

    def log_summary(result)
      Rails.logger.info(
        "[CompressRecentJob] day=#{result.day} targets=#{result.chapter_ids.size} compressed=#{result.compressed} " \
        "unchanged=#{result.unchanged} skipped=#{result.skipped} errors=#{result.errors.size}"
      )
    end
  end
end
