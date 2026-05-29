# frozen_string_literal: true

require 'test_helper'

class SyncAllChannelsVideosJobTest < ActiveSupport::TestCase
  test 'perform is a no-op outside production' do
    called = false

    Youtube::VideosJob.stub(:perform_later, ->(*) { called = true }) do
      Youtube::SyncAllChannelsVideosJob.new.perform
    end

    assert_not called
  end

  test 'perform enqueues a VideosJob per channel in production' do
    enqueued_channel_ids = []

    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      Youtube::VideosJob.stub(:perform_later, ->(channel_id) { enqueued_channel_ids << channel_id }) do
        Youtube::SyncAllChannelsVideosJob.new.perform
      end
    end

    assert_equal YoutubeChannel.pluck(:channel_id), enqueued_channel_ids
  end
end
