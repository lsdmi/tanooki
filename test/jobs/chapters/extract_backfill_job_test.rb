# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ExtractBackfillJobTest < ActiveSupport::TestCase
    setup do
      @original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    end

    teardown do
      Rails.cache = @original_cache
    end

    test 'runs on the serialized heavy queue' do
      assert_equal "#{Rails.env}_heavy", ExtractBackfillJob.new.queue_name
    end

    test 'outside the night window it waits for the next window with the same cursor' do
      travel_to Time.zone.local(2026, 9, 28, 14, 0) do
        ExtractBackfill.stub(:call, ->(**) { flunk 'must not scan outside the window' }) do
          ExtractBackfillJob.perform_now(500, 123)
        end

        assert_next_batch [500, 0], dry_run: false, at: Time.zone.local(2026, 9, 29, 2, 0)
      end
    end

    test 'in the window it runs one batch and queues the next after a pause' do
      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        ExtractBackfill.stub(:call, result(to_id: 700, before_bytes: 10.megabytes)) do
          ExtractBackfillJob.perform_now(500, 1.megabyte)
        end

        assert_next_batch [700, 11.megabytes], dry_run: false, at: ExtractBackfillJob::PAUSE.from_now
      end
    end

    test 'stops for the night once the byte budget is spent' do
      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        ExtractBackfill.stub(:call, result(to_id: 700, before_bytes: ExtractBackfillJob::NIGHTLY_BUDGET_BYTES)) do
          ExtractBackfillJob.perform_now(500, 0)
        end

        assert_next_batch [700, 0], dry_run: false, at: Time.zone.local(2026, 9, 30, 2, 0)
      end
    end

    test 'finishes without queuing another batch' do
      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        ExtractBackfill.stub(:call, result(to_id: 900, done: true)) { ExtractBackfillJob.perform_now(700, 0) }
      end

      assert_empty ExtractBackfillJob.pending
    end

    test 'the stop flag ends the chain' do
      Rails.cache.write(ExtractBackfillJob::STOP_KEY, true)

      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        ExtractBackfill.stub(:call, ->(**) { flunk 'must not scan when stopped' }) do
          ExtractBackfillJob.perform_now(500, 0)
        end
      end

      assert_empty ExtractBackfillJob.pending
    end

    test 'passes the worker body limit and keeps dry run through the chain' do
      received = nil
      fake = lambda do |**kwargs|
        received = kwargs
        result(to_id: 700)
      end

      travel_to Time.zone.local(2026, 9, 29, 3, 0) do
        ExtractBackfill.stub(:call, fake) { ExtractBackfillJob.perform_now(500, 0, dry_run: true) }

        assert_next_batch [700, 0], dry_run: true, at: ExtractBackfillJob::PAUSE.from_now
      end
      assert_equal ExtractBackfillJob::MAX_BODY_BYTES, received[:max_body_bytes]
      assert received[:dry_run]
    end

    test 'start refuses while a backfill is already queued and clears an old stop flag' do
      Rails.cache.write(ExtractBackfillJob::STOP_KEY, true)

      ExtractBackfillJob.start!('42', dry_run: true)

      assert_nil Rails.cache.read(ExtractBackfillJob::STOP_KEY)
      assert_not ExtractBackfillJob.start!
      assert_match(/after_id=42 night_bytes=0 .* status=ready/, ExtractBackfillJob.status_lines.sole)
    end

    test 'stop removes the queued batch and frees the concurrency lock for a restart' do
      ExtractBackfillJob.start!

      assert_equal 1, ExtractBackfillJob.stop!
      assert Rails.cache.read(ExtractBackfillJob::STOP_KEY)

      ExtractBackfillJob.start!

      assert_predicate ExtractBackfillJob.pending.sole, :ready?
    end

    private

    def assert_next_batch(cursor, dry_run:, at:)
      job = ExtractBackfillJob.pending.sole
      after_id, night_bytes, options = job.arguments['arguments']

      assert_equal [*cursor, dry_run], [after_id, night_bytes, options['dry_run']]
      assert_in_delta at.to_f, job.scheduled_at.to_f, 1
    end

    def result(to_id:, before_bytes: 0, done: false)
      ExtractBackfill::Result.new(
        after_id: 0, to_id:, done:, candidates: 1, candidate_bytes: before_bytes, extracted: 1, unchanged: 0,
        images: 1, failed_images: 0, skipped: [], errors: [], before_bytes:, after_bytes: before_bytes / 4
      )
    end
  end
end
