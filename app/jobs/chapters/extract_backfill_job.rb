# frozen_string_literal: true

module Chapters
  # Self-rescheduling backfill that moves inline base64 images out of old chapter bodies.
  # Each run handles one ExtractBackfill batch and enqueues the next with the cursor
  # (last scanned rich text id), so progress survives deploys in solid_queue_jobs.
  # Start and stop with `rake chapters:extract_backfill:{start,status,stop}`.
  class ExtractBackfillJob < ApplicationJob
    SCAN_SIZE = 200
    PAUSE = 20.seconds
    # Peak memory is about twice the body; larger bodies go through the local rake pass.
    MAX_BODY_BYTES = ExtractInlineImagesJob::MAX_BODY_BYTES
    # Kyiv hours with the least traffic. Rewritten bodies also land in the binlog, so each
    # night stops after this many bytes of rewritten bodies to keep disk growth gradual.
    WINDOW_HOURS = (2...7)
    NIGHTLY_BUDGET_BYTES = 1.gigabyte
    STOP_KEY = 'chapters_extract_backfill:stop'

    queue_as :heavy
    limits_concurrency key: 'chapters_extract_backfill', to: 1, duration: 1.hour

    class << self
      def pending
        SolidQueue::Job.where(class_name: name, finished_at: nil)
      end

      def start!(start_id = 0, dry_run: false)
        return false if pending.exists?

        Rails.cache.delete(STOP_KEY)
        perform_later(start_id.to_i, 0, dry_run:)
      end

      # destroy, not delete: a ready job holds the concurrency lock and only its callback releases it.
      # A batch already running finishes and its successor exits on the stop flag.
      def stop!
        Rails.cache.write(STOP_KEY, true, expires_in: 30.days)
        pending.where.missing(:claimed_execution).destroy_all.size
      end

      def status_lines
        pending.order(:id).map do |job|
          after_id, night_bytes = job.arguments['arguments']
          "job=#{job.id} after_id=#{after_id} night_bytes=#{night_bytes} " \
            "scheduled_at=#{job.scheduled_at&.in_time_zone} status=#{job.status || 'scheduled'}"
        end
      end
    end

    def perform(after_id = 0, night_bytes = 0, dry_run: false)
      return Rails.logger.info("[ExtractBackfillJob] stopped at after_id=#{after_id}") if Rails.cache.read(STOP_KEY)
      return continue_at(next_window_start, after_id, 0, dry_run) unless off_peak?

      run_batch(after_id, night_bytes, dry_run)
    end

    private

    def run_batch(after_id, night_bytes, dry_run)
      result = ExtractBackfill.call(after_id:, scan_size: SCAN_SIZE, max_body_bytes: MAX_BODY_BYTES, dry_run:)
      log_batch(result)
      return log_finished if result.done

      night_bytes += result.before_bytes
      return continue_at(next_window_start, result.to_id, 0, dry_run) if night_bytes >= NIGHTLY_BUDGET_BYTES

      continue_at(PAUSE.from_now, result.to_id, night_bytes, dry_run)
    end

    def off_peak?
      WINDOW_HOURS.cover?(Time.current.hour)
    end

    def next_window_start
      start = Time.current.change(hour: WINDOW_HOURS.begin)
      start.future? ? start : start + 1.day
    end

    def continue_at(time, after_id, night_bytes, dry_run)
      self.class.set(wait_until: time).perform_later(after_id, night_bytes, dry_run:)
    end

    def log_batch(result)
      Rails.logger.info(
        "[ExtractBackfillJob] ids=#{result.after_id + 1}..#{result.to_id} " \
        "candidates=#{result.candidates} candidate_bytes=#{result.candidate_bytes} " \
        "extracted=#{result.extracted} images=#{result.images} failed_images=#{result.failed_images} " \
        "unchanged=#{result.unchanged} skipped=#{result.skipped.size} errors=#{result.errors.size} " \
        "bytes=#{result.before_bytes}->#{result.after_bytes}"
      )
    end

    def log_finished
      Rails.logger.info('[ExtractBackfillJob] finished: reached the last rich text id')
    end
  end
end
