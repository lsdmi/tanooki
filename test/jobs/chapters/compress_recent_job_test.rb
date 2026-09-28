# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressRecentJobTest < ActiveJob::TestCase
    test 'runs on the serialized heavy queue' do
      assert_equal "#{Rails.env}_heavy", CompressRecentJob.new.queue_name
    end

    test 'compresses with the body size limit' do
      received = nil
      fake = lambda do |**kwargs|
        received = kwargs
        result
      end

      CompressRecent.stub(:call, fake) { CompressRecentJob.perform_now }

      assert_equal({ max_body_bytes: CompressRecentJob::MAX_BODY_BYTES }, received)
    end

    test 'raises when some chapters failed' do
      failing = result(errors: [{ chapter_id: 1, error: 'boom' }])

      CompressRecent.stub(:call, failing) do
        assert_raises(ApplicationJob::BatchErrors) { CompressRecentJob.perform_now }
      end
    end

    private

    def result(errors: [])
      CompressRecent::Result.new(
        day: Date.current, chapter_ids: [1], compressed: 1, unchanged: 0, skipped: 0, errors:
      )
    end
  end
end
