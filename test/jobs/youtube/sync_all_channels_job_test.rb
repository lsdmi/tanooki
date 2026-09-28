# frozen_string_literal: true

require 'test_helper'

module Youtube
  class SyncAllChannelsJobTest < ActiveJob::TestCase
    test 'syncs every channel' do
      ok = SyncAllChannelsVideos::Result.new(channel_ids: %w[a b], synced: 2, errors: [])

      SyncAllChannelsVideos.stub(:call, ok) do
        assert_nothing_raised { SyncAllChannelsJob.perform_now }
      end
    end

    test 'raises when some channels failed' do
      failing = SyncAllChannelsVideos::Result.new(
        channel_ids: %w[a], synced: 0, errors: [{ channel_id: 'a', error: 'quota' }]
      )

      SyncAllChannelsVideos.stub(:call, failing) do
        assert_raises(ApplicationJob::BatchErrors) { SyncAllChannelsJob.perform_now }
      end
    end
  end
end
