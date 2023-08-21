# frozen_string_literal: true

require 'google/apis/youtube_v3'

module Youtube
  class VideosJob < ApplicationJob
    queue_as :default

    MAX_TAG_LENGTH = 255

    def perform(channel_id)
      youtube = Google::Apis::YoutubeV3::YouTubeService.new
      youtube.key = ENV.fetch('YOUTUBE_API_KEY')

      response = youtube.list_searches('snippet', channel_id:, max_results: 5, type: 'video', order: 'date')
      video_ids = response.items.map { |item| item.id.video_id }.compact

      video_ids.each do |video_id|
        create_video(youtube, channel_id, video_id) unless YoutubeVideo.with_deleted.exists?(video_id:)
      end
    end

    private

    def create_video(youtube, channel_id, video_id)
      video_data = video_data(youtube.list_videos('snippet', id: video_id))

      YoutubeVideo.create(
        youtube_channel: YoutubeChannel.find_by(channel_id:),
        video_id:,
        title: video_data.title,
        description: video_data.description,
        thumbnail: select_thumbnail(video_data.thumbnails),
        tags: trimmed_tags(video_data.tags),
        published_at: video_data.published_at
      )
    end

    def trimmed_tags(tags)
      return nil if tags.nil?

      total_length = 0
      selected_tags = tags.take_while do |tag|
        total_length += tag.length + 2
        total_length <= MAX_TAG_LENGTH
      end

      selected_tags.join(', ')
    end

    def select_thumbnail(thumbnails)
      selected = thumbnails.maxres || thumbnails.standard || thumbnails.high || thumbnails.medium || thumbnails.default
      selected.url
    end

    def video_data(response)
      response.items.first.snippet
    end
  end
end
