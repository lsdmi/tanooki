# frozen_string_literal: true

require 'test_helper'

class EpubExportRequestJobStatusSyncTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_one)
    @rich_text_ids = [action_text_rich_texts(:rich_text_four).id]
  end

  test 'sync_with_job_status! fails processing export when generate job failed' do
    export = create_processing_export
    create_failed_generate_job(export)

    export.sync_with_job_status!

    assert_predicate export.reload, :failed?
  end

  test 'sync_with_job_status! fails processing export when job is claimed by dead worker' do
    export = create_processing_export(updated_at: 20.minutes.ago)
    claim_export_with_stale_worker(export)

    export.sync_with_job_status!

    assert_predicate export.reload, :failed?
  end

  test 'sync_with_job_status! fails processing export when worker died after job started' do
    export = create_processing_export(updated_at: 3.minutes.ago, processing_step: 'chapter_1 image 1')
    job = create_generate_job(export)
    process = stale_worker_process(last_heartbeat_at: export.created_at - 1.minute)
    SolidQueue::ClaimedExecution.create!(job: job, process: process)

    export.sync_with_job_status!

    assert_predicate export.reload, :failed?
  end

  test 'sync_with_job_status! keeps processing export when progress updated recently' do
    export = create_processing_export(processing_step: 'chapter 3/10')
    claim_export_with_stale_worker(export)

    export.sync_with_job_status!

    assert_predicate export.reload, :processing?
  end

  private

  def create_processing_export(**attrs)
    EpubExportRequest.create!(user: @user, rich_text_ids: @rich_text_ids, status: :processing, **attrs)
  end

  def create_failed_generate_job(export)
    SolidQueue::Job.create!(
      queue_name: 'test_default',
      class_name: 'Books::GenerateEpubJob',
      arguments: { job_class: 'Books::GenerateEpubJob', arguments: [export.id] },
      priority: 0,
      active_job_id: SecureRandom.uuid,
      scheduled_at: Time.current
    ).tap do |job|
      SolidQueue::FailedExecution.create!(job: job, error: { exception_class: 'RuntimeError', message: 'boom' })
    end
  end

  def claim_export_with_stale_worker(export, heartbeat_at: 20.minutes.ago)
    process = stale_worker_process(last_heartbeat_at: heartbeat_at)
    job = create_generate_job(export)
    SolidQueue::ClaimedExecution.create!(job: job, process: process)
  end

  def stale_worker_process(last_heartbeat_at: 20.minutes.ago)
    SolidQueue::Process.create!(
      kind: 'Worker',
      name: 'worker-test',
      pid: Process.pid,
      hostname: 'test',
      metadata: {},
      last_heartbeat_at: last_heartbeat_at,
      created_at: Time.current
    )
  end

  def create_generate_job(export)
    SolidQueue::Job.create!(
      queue_name: 'test_default',
      class_name: 'Books::GenerateEpubJob',
      arguments: { job_class: 'Books::GenerateEpubJob', arguments: [export.id] },
      priority: 0,
      active_job_id: SecureRandom.uuid,
      scheduled_at: Time.current
    )
  end
end
