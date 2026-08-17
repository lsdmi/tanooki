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
  end
end
