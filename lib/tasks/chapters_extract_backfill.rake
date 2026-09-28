# frozen_string_literal: true

namespace :chapters do
  namespace :extract_backfill do
    desc 'Start the nightly inline image extraction in the worker (START_ID=0, DRY_RUN=1 to only log candidates)'
    task start: :environment do
      dry_run = ENV['DRY_RUN'].present?
      started = Chapters::ExtractBackfillJob.start!(ENV.fetch('START_ID', 0), dry_run:)
      puts started ? "enqueued dry_run=#{dry_run}; runs 2:00-7:00 Kyiv" : 'already running; see status'
    end

    desc 'Show the backfill cursor and when the next batch runs'
    task status: :environment do
      puts Chapters::ExtractBackfillJob.status_lines.presence || 'no pending backfill job'
    end

    desc 'Stop the backfill: the running batch finishes, nothing new starts'
    task stop: :environment do
      puts "stop flag set; removed #{Chapters::ExtractBackfillJob.stop!} queued job(s)"
    end

    desc 'Extract images from bodies too large for the worker, from a laptop via bin/prod-db (MIN_BODY_MB=16)'
    task local: :environment do
      min_body_bytes = ENV.fetch('MIN_BODY_MB', 16).to_i.megabytes
      Chapters::ExtractBackfill.run_local(after_id: ENV.fetch('START_ID', 0), min_body_bytes:) do |batch|
        puts "ids=#{batch.after_id + 1}..#{batch.to_id} candidates=#{batch.candidates} errors=#{batch.errors.size} " \
             "under_min=#{batch.skipped.size} extracted=#{batch.extracted} images=#{batch.images} " \
             "failed_images=#{batch.failed_images} bytes=#{batch.before_bytes}->#{batch.after_bytes}"
      end
    end
  end
end
