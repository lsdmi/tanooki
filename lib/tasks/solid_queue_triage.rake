# frozen_string_literal: true

namespace :solid_queue do
  desc 'Fail stale EPUB exports, retry recent safe failures, purge old failed job rows'
  task triage: :environment do
    SolidQueue::TriageFailedJobsJob.perform_now
    puts 'Solid Queue triage complete.'
  end
end
