# frozen_string_literal: true

namespace :chapters do
  namespace :compress_backfill do
    desc 'Start the nightly inline image backfill in the worker (START_ID=0, DRY_RUN=1 to only log candidates)'
    task start: :environment do
      dry_run = ENV['DRY_RUN'].present?
      started = Chapters::CompressBackfillJob.start!(ENV.fetch('START_ID', 0), dry_run:)
      puts started ? "enqueued dry_run=#{dry_run}; runs 2:00-7:00 Kyiv" : 'already running; see status'
    end

    desc 'Show the backfill cursor and when the next batch runs'
    task status: :environment do
      puts Chapters::CompressBackfillJob.status_lines.presence || 'no pending backfill job'
    end

    desc 'Stop the backfill: the running batch finishes, nothing new starts'
    task stop: :environment do
      puts "stop flag set; removed #{Chapters::CompressBackfillJob.stop!} queued job(s)"
    end

    desc 'Compress bodies too large for the worker, from a laptop via bin/prod-db (MIN_BODY_MB=16, START_ID=0)'
    task local: :environment do
      min_body_bytes = ENV.fetch('MIN_BODY_MB', 16).to_i.megabytes
      Chapters::CompressBackfill.run_local(after_id: ENV.fetch('START_ID', 0), min_body_bytes:) do |result|
        puts "ids=#{result.after_id + 1}..#{result.to_id} candidates=#{result.candidates} " \
             "compressed=#{result.compressed} bytes=#{result.before_bytes}->#{result.after_bytes} " \
             "errors=#{result.errors.size}"
      end
    end
  end
end
