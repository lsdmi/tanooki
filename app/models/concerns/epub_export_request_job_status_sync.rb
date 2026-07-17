# frozen_string_literal: true

# Syncs processing exports with Solid Queue job failures and orphaned worker claims.
module EpubExportRequestJobStatusSync
  extend ActiveSupport::Concern

  STUCK_WORKER_AFTER = 15.minutes

  class_methods do
    def sync_processing_for(user)
      user.epub_export_requests.processing.find_each(&:sync_with_job_status!)
    end
  end

  def sync_with_job_status!
    fail_if_stale_processing!
    return unless processing?
    return unless generate_job_failed? || generate_job_stuck?

    fail_from_interrupted_job!
  end

  private

  def fail_from_interrupted_job!
    update!(
      status: :failed,
      error_message: I18n.t('downloads.epub_export.generation_interrupted')
    )
  end

  def generate_job_failed?
    latest_generate_job&.failed_execution.present?
  end

  def generate_job_stuck?
    job = latest_generate_job
    return false unless job&.claimed_execution

    process = SolidQueue::Process.find_by(id: job.claimed_execution.process_id)
    return true if process.nil?

    heartbeat = process.last_heartbeat_at
    return true if orphaned_by_dead_worker?(job, heartbeat)

    return false if updated_at >= STUCK_WORKER_AFTER.ago

    heartbeat < STUCK_WORKER_AFTER.ago
  end

  def orphaned_by_dead_worker?(job, heartbeat)
    heartbeat < job.created_at - 30.seconds && updated_at < 2.minutes.ago
  end

  def latest_generate_job
    SolidQueue::Job.where(class_name: 'Books::GenerateEpubJob')
                   .where('arguments LIKE ?', "%\"arguments\":[#{id}]%")
                   .order(id: :desc)
                   .first
  end
end
