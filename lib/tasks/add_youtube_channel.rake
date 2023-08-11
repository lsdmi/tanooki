# frozen_string_literal: true

require 'google/apis/youtube_v3'

# Purpose: add new youtube channel record
# Usage:   rake "add_youtube_channel[UCU0_b5vMohoxvxWvoQUxaqg]"

task :add_youtube_channel, [:channel_id] => :environment do |_task, args|
  youtube = Google::Apis::YoutubeV3::YouTubeService.new
  youtube.key = ENV.fetch('YOUTUBE_API_KEY')

  channel = youtube.list_channels('snippet', id: args[:channel_id]).items.first

  YoutubeChannel.create(
    channel_id: args[:channel_id],
    description: channel.snippet.description,
    thumbnail: channel.snippet.thumbnails.default.url,
    title: channel.snippet.title
  )
end
