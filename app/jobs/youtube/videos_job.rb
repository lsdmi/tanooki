# frozen_string_literal: true

require 'google/apis/youtube_v3'

module Youtube
  class VideosJob < ApplicationJob
    queue_as :default

    MAX_TAG_LENGTH = 255

    def perform(channel_id)
      youtube = initialize_youtube_service
      video_ids = fetch_video_ids(youtube, channel_id)
      ActiveRecord::Base.transaction { create_videos_if_not_exists(youtube, channel_id, video_ids) }
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

    def create_videos_if_not_exists(youtube, channel_id, video_ids)
      video_ids.each do |video_id|
        next if short_video?(youtube, video_id)
        next if YoutubeVideo.with_deleted.exists?(video_id:)

        create_video(youtube, channel_id, video_id)
      end
    end

    def fetch_video_ids(youtube, channel_id)
      response = youtube.list_searches('snippet', channel_id:, max_results: 5, type: 'video', order: 'date')
      response.items.map { |item| item.id.video_id }.compact
    end

    def short_video?(youtube, video_id)
      response = youtube.list_videos('contentDetails', id: video_id)
      item = response.items.first
      return false unless item&.content_details&.duration

      duration_seconds = parse_youtube_duration(item.content_details.duration.to_s)
      duration_seconds <= 60
    end

    def initialize_youtube_service
      youtube = Google::Apis::YoutubeV3::YouTubeService.new
      youtube.key = ENV.fetch('YOUTUBE_API_KEY')
      youtube
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

    def parse_youtube_duration(iso8601_duration)
      match = iso8601_duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
      return 0 unless match

      hours = match[1].to_i
      minutes = match[2].to_i
      seconds = match[3].to_i
      (hours * 3600) + (minutes * 60) + seconds
    end
  end
end
