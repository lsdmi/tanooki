# frozen_string_literal: true

module Youtube
  # Enqueues one VideosJob per channel so channels sync in parallel and failures stay isolated.
  class SyncAllChannelsVideosJob < ApplicationJob
    queue_as :default

    def perform
      return unless Rails.env.production?

      YoutubeChannel.find_each do |channel|
        VideosJob.perform_later(channel.channel_id)
      end
    end
  end
end
