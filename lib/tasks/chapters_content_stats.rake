# frozen_string_literal: true

namespace :chapters do
  desc 'Enqueue the one-shot word_count / excerpt / body_bytes backfill (AFTER_ID=0)'
  task backfill_content_stats: :environment do
    after_id = ENV.fetch('AFTER_ID', 0).to_i
    Chapters::ContentStatsBackfillJob.perform_later(after_id)
    puts "enqueued Chapters::ContentStatsBackfillJob after_id=#{after_id}"
  end
end
