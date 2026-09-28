# frozen_string_literal: true

namespace :youtube do
  desc 'Sync latest videos for all YoutubeChannel records (manual run; scheduled in config/recurring.yml)'
  task sync_all_channels: :environment do
    result = Youtube::SyncAllChannelsVideos.call

    puts "channels=#{result.channel_ids.size} synced=#{result.synced} errors=#{result.errors.size}"
    result.errors.each { |error| puts "  channel=#{error[:channel_id]} #{error[:error]}" }

    abort 'youtube:sync_all_channels failed' if result.errors.any?
  end
end
