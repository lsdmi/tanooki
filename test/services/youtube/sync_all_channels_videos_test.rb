# frozen_string_literal: true

require 'test_helper'

module Youtube
  class SyncAllChannelsVideosTest < ActiveSupport::TestCase
    test 'call reports synced channel ids' do
      channel_ids = YoutubeChannel.order(:id).pluck(:channel_id)

      SyncChannelVideos.stub(:call, ->(*) {}) do
        result = SyncAllChannelsVideos.call

        assert_equal channel_ids, result.channel_ids
        assert_equal channel_ids.size, result.synced
        assert_empty result.errors
      end
    end

    test 'call isolates a failing channel' do
      channel_ids = YoutubeChannel.order(:id).pluck(:channel_id)
      failing_id = channel_ids.first

      SyncChannelVideos.stub(:call, lambda { |channel_id|
        raise StandardError, 'boom' if channel_id == failing_id
      }) do
        result = SyncAllChannelsVideos.call

        assert_equal 1, result.errors.size
        assert_equal failing_id, result.errors.first[:channel_id]
        assert_match(/boom/, result.errors.first[:error])
      end
    end

    test 'call retries a channel once after a YouTube error' do
      calls = Hash.new(0)
      flaky_id = YoutubeChannel.order(:id).pick(:channel_id)

      SyncChannelVideos.stub(:call, lambda { |channel_id|
        calls[channel_id] += 1
        raise Google::Apis::ClientError, 'forbidden' if channel_id == flaky_id && calls[channel_id] == 1
      }) do
        result = sync_without_retry_delay

        assert_empty result.errors
        assert_equal 2, calls[flaky_id]
      end
    end

    test 'call reports a channel whose YouTube error persists after the retry' do
      failing_id = YoutubeChannel.order(:id).pick(:channel_id)

      SyncChannelVideos.stub(:call, lambda { |channel_id|
        raise Google::Apis::ClientError, 'forbidden' if channel_id == failing_id
      }) do
        result = sync_without_retry_delay

        assert_equal [failing_id], result.errors.pluck(:channel_id)
        assert_match(/forbidden/, result.errors.first[:error])
      end
    end

    private

    def sync_without_retry_delay
      service = SyncAllChannelsVideos.new
      service.stub(:sleep, nil) { service.call }
    end
  end
end
