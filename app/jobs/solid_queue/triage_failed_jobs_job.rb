# frozen_string_literal: true

module SolidQueue
  # Hourly cleanup: unblock stale EPUB exports, retry safe recent failures, purge old dead jobs.
  class TriageFailedJobsJob < ApplicationJob
    RETRYABLE_JOB_CLASSES = %w[
      Analytics::ViewIncrementJob
      Books::GenerateEpubJob
      Fictions::WarmIndexCacheJob
      Searchkick::SyncSoftDeletableJob
      Searchkick::ReindexV2Job
      Fictions::RefreshDroppedStatusJob
      Youtube::SyncAllChannelsVideosJob
      Youtube::VideosJob
    ].freeze

    RETRY_WINDOW = 7.days
    RETRY_LIMIT = 50
    PURGE_AFTER = 14.days

    def perform
      fail_epub_exports_with_failed_jobs
      fail_stale_epub_exports
      retry_recent_failures
      purge_old_failed_jobs
    end

    private

    def fail_epub_exports_with_failed_jobs
      EpubExportRequest.processing.find_each(&:sync_with_job_status!)
    end

    def fail_stale_epub_exports
      EpubExportRequest.processing.find_each(&:fail_if_stale_processing!)
    end

    def retry_recent_failures
      jobs = SolidQueue::Job.where(finished_at: nil)
                            .failed
                            .where(class_name: RETRYABLE_JOB_CLASSES)
                            .where(created_at: RETRY_WINDOW.ago..)
                            .order(created_at: :desc)
                            .limit(RETRY_LIMIT)

      SolidQueue::FailedExecution.retry_all(jobs) if jobs.exists?
    end

    def purge_old_failed_jobs
      loop do
        stale_job_ids = SolidQueue::Job.where(finished_at: nil)
                                       .failed
                                       .where(created_at: ...PURGE_AFTER.ago)
                                       .limit(500)
                                       .pluck(:id)
        break if stale_job_ids.empty?

        SolidQueue::Job.where(id: stale_job_ids).delete_all
      end
    end
  end
end
