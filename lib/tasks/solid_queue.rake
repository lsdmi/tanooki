# frozen_string_literal: true

namespace :solid_queue do
  desc 'Delete finished Solid Queue job rows in batches (CI / laptop)'
  task clear_finished: :environment do
    SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)
    puts 'Solid Queue finished jobs cleared.'
  end

  desc 'Fail stale EPUB exports, retry recent safe failures, purge old failed job rows'
  task triage: :environment do
    SolidQueue::TriageFailedJobsJob.perform_now
    puts 'Solid Queue triage complete.'
  end
end
