# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressBackfillJobTest < ActiveSupport::TestCase
    setup do
      @original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    end

    teardown do
      Rails.cache = @original_cache
    end

    test 'runs on the serialized heavy queue' do
      assert_equal "#{Rails.env}_heavy", CompressBackfillJob.new.queue_name
    end

    test 'outside the night window it waits for the next window with the same cursor' do
      travel_to Time.zone.local(2026, 9, 28, 14, 0) do
        CompressBackfill.stub(:call, ->(**) { flunk 'must not scan outside the window' }) do
          CompressBackfillJob.perform_now(500, 123)
        end

        assert_next_batch [500, 0], dry_run: false, at: Time.zone.local(2026, 9, 29, 2, 0)
      end
    end

    test 'in the window it runs one batch and queues the next after a pause' do
      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        CompressBackfill.stub(:call, result(to_id: 700, before_bytes: 10.megabytes)) do
          CompressBackfillJob.perform_now(500, 1.megabyte)
        end

        assert_next_batch [700, 11.megabytes], dry_run: false, at: CompressBackfillJob::PAUSE.from_now
      end
    end

    test 'stops for the night once the byte budget is spent' do
      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        CompressBackfill.stub(:call, result(to_id: 700, before_bytes: CompressBackfillJob::NIGHTLY_BUDGET_BYTES)) do
          CompressBackfillJob.perform_now(500, 0)
        end

        assert_next_batch [700, 0], dry_run: false, at: Time.zone.local(2026, 9, 30, 2, 0)
      end
    end

    test 'finishes without queuing another batch' do
      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        CompressBackfill.stub(:call, result(to_id: 900, done: true)) { CompressBackfillJob.perform_now(700, 0) }
      end

      assert_empty CompressBackfillJob.pending
    end

    test 'the stop flag ends the chain' do
      Rails.cache.write(CompressBackfillJob::STOP_KEY, true)

      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        CompressBackfill.stub(:call, ->(**) { flunk 'must not scan when stopped' }) do
          CompressBackfillJob.perform_now(500, 0)
        end
      end

      assert_empty CompressBackfillJob.pending
    end

    test 'passes the worker body limit and keeps dry run through the chain' do
      received = nil
      fake = lambda do |**kwargs|
        received = kwargs
        result(to_id: 700)
      end

      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        CompressBackfill.stub(:call, fake) { CompressBackfillJob.perform_now(500, 0, dry_run: true) }

        assert_next_batch [700, 0], dry_run: true, at: CompressBackfillJob::PAUSE.from_now
      end
      assert_equal CompressBackfillJob::MAX_BODY_BYTES, received[:max_body_bytes]
      assert received[:dry_run]
    end

    test 'start refuses while a backfill is already queued and clears an old stop flag' do
      Rails.cache.write(CompressBackfillJob::STOP_KEY, true)

      CompressBackfillJob.start!('42', dry_run: true)

      assert_nil Rails.cache.read(CompressBackfillJob::STOP_KEY)
      assert_not CompressBackfillJob.start!
      assert_match(/after_id=42 night_bytes=0 .* status=ready/, CompressBackfillJob.status_lines.sole)
    end

    test 'stop removes the queued batch and frees the concurrency lock for a restart' do
      CompressBackfillJob.start!

      assert_equal 1, CompressBackfillJob.stop!
      assert Rails.cache.read(CompressBackfillJob::STOP_KEY)

      CompressBackfillJob.start!

      assert_predicate CompressBackfillJob.pending.sole, :ready?
    end

    private

    def assert_next_batch(cursor, dry_run:, at:)
      job = CompressBackfillJob.pending.sole
      after_id, night_bytes, options = job.arguments['arguments']

      assert_equal [*cursor, dry_run], [after_id, night_bytes, options['dry_run']]
      assert_in_delta at.to_f, job.scheduled_at.to_f, 1
    end

    def result(to_id:, before_bytes: 0, done: false)
      CompressBackfill::Result.new(
        after_id: 0, to_id:, done:, candidates: 1, candidate_bytes: before_bytes, compressed: 1, unchanged: 0,
        skipped: [], errors: [], before_bytes:, after_bytes: before_bytes / 4
      )
    end
  end
end
