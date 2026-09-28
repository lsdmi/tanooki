# frozen_string_literal: true

module Youtube
  # Daily: import the latest videos for every YoutubeChannel (config/recurring.yml).
  class SyncAllChannelsJob < ApplicationJob
    queue_as :default

    def perform
      result = SyncAllChannelsVideos.call
      Rails.logger.info(
        "[SyncAllChannelsJob] channels=#{result.channel_ids.size} synced=#{result.synced} errors=#{result.errors.size}"
      )
      raise BatchErrors, "#{result.errors.size} channels failed: #{result.errors.first(5)}" if result.errors.any?
    end
  end
end
