# frozen_string_literal: true

require 'test_helper'

module SolidQueue
  class TriageFailedJobsJobTest < ActiveSupport::TestCase
    test 'perform fails stale processing epub exports' do
      export = EpubExportRequest.create!(
        user: users(:user_one),
        rich_text_ids: [action_text_rich_texts(:rich_text_four).id],
        status: :processing
      )
      export.update_column(:updated_at, 31.minutes.ago) # rubocop:disable Rails/SkipsModelValidations

      TriageFailedJobsJob.perform_now

      assert_predicate export.reload, :failed?
    end
  end
end
