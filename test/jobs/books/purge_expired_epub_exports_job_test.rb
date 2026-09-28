# frozen_string_literal: true

require 'test_helper'

module Books
  class PurgeExpiredEpubExportsJobTest < ActiveJob::TestCase
    test 'purges expired exports' do
      ok = PurgeExpiredEpubExports::Result.new(purged: 3, errors: [])

      PurgeExpiredEpubExports.stub(:call, ok) do
        assert_nothing_raised { PurgeExpiredEpubExportsJob.perform_now }
      end
    end

    test 'raises when some exports failed' do
      failing = PurgeExpiredEpubExports::Result.new(purged: 0, errors: [{ export_id: 1, error: 'boom' }])

      PurgeExpiredEpubExports.stub(:call, failing) do
        assert_raises(ApplicationJob::BatchErrors) { PurgeExpiredEpubExportsJob.perform_now }
      end
    end
  end
end
