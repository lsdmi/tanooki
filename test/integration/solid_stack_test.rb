# frozen_string_literal: true

require 'test_helper'

class SolidStackTest < ActiveSupport::TestCase
  test 'test environment uses solid cache and queue adapters' do
    assert_equal :solid_cache_store, Rails.application.config.cache_store
    assert_equal :solid_queue, Rails.application.config.active_job.queue_adapter.to_sym
  end

  test 'solid cache store reads and writes' do
    Rails.cache.write('solid_stack_test', 'ok', expires_in: 1.minute)

    assert_equal 'ok', Rails.cache.read('solid_stack_test')
  end

  test 'solid queue persists enqueued jobs' do
    job = Fictions::WarmIndexCacheJob.perform_later

    assert_predicate SolidQueue::Job.find_by(active_job_id: job.job_id), :present?
  end
end
