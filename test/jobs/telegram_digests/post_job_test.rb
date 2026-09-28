# frozen_string_literal: true

require 'test_helper'

module TelegramDigests
  class PostJobTest < ActiveJob::TestCase
    test 'posts the named digest' do
      posted = nil

      Post.stub(:call, ->(digest) { posted = digest }) { PostJob.perform_now('fictions') }

      assert_equal 'fictions', posted
    end

    test 'is not in the automatic retry list' do
      assert_not_includes SolidQueue::TriageFailedJobsJob::RETRYABLE_JOB_CLASSES, PostJob.name
    end
  end
end
