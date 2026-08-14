# frozen_string_literal: true

require 'test_helper'

module SolidQueue
  class TriageFailedJobsJobTest < ActiveSupport::TestCase
    test 'perform fails stale processing epub exports' do
      export = nil

      travel_to 31.minutes.ago do
        export = EpubExportRequest.create!(
          user: users(:user_one),
          rich_text_ids: [action_text_rich_texts(:rich_text_four).id],
          status: :processing
        )
      end

      TriageFailedJobsJob.perform_now

      assert_predicate export.reload, :failed?
    end

    test 'retryable list includes per-chapter compress jobs' do
      assert_includes TriageFailedJobsJob::RETRYABLE_JOB_CLASSES, 'Chapters::CompressInlineImagesJob'
    end

    test 'retryable list excludes fan-out mailer and analyze jobs' do
      excluded = %w[
        Chapters::CompressRecentInlineImagesJob
        ActionMailer::MailDeliveryJob
        ActiveStorage::AnalyzeJob
      ]

      assert_empty(excluded & TriageFailedJobsJob::RETRYABLE_JOB_CLASSES)
    end
  end
end
