# frozen_string_literal: true

require 'google/apis/youtube_v3'

module Youtube
  # Imports the latest non-short videos from one YouTube channel into YoutubeVideo records.
  class SyncChannelVideos
    MAX_TAG_LENGTH = 255

    def self.call(channel_id)
      new(channel_id).call
    end

    def initialize(channel_id)
      @channel_id = channel_id
    end

    def call
      youtube = initialize_youtube_service
      video_ids = unknown_video_ids(fetch_video_ids(youtube))
      return if video_ids.empty?

      videos = fetch_videos(youtube, video_ids).reject { |video| short_video?(video) }
      youtube_channel = YoutubeChannel.find_by(channel_id: @channel_id)
      ActiveRecord::Base.transaction { videos.each { |video| create_video(youtube_channel, video) } }
    end

    private

    def create_video(youtube_channel, video)
      snippet = video.snippet

      YoutubeVideo.create(
        youtube_channel:,
        video_id: video.id,
        title: snippet.title,
        description: snippet.description,
        thumbnail: select_thumbnail(snippet.thumbnails),
        tags: trimmed_tags(snippet.tags),
        published_at: snippet.published_at
      )
    end

    def unknown_video_ids(video_ids)
      video_ids - YoutubeVideo.with_deleted.where(video_id: video_ids).pluck(:video_id)
    end

    def fetch_videos(youtube, video_ids)
      youtube.list_videos('snippet,contentDetails', id: video_ids.join(',')).items
    end

    def fetch_video_ids(youtube)
      response = youtube.list_playlist_items(
        'snippet',
        playlist_id: uploads_playlist_id,
        max_results: 5
      )
      response.items.filter_map { |item| item.snippet.resource_id.video_id }
    end

    def uploads_playlist_id
      @channel_id.to_s.sub(/\AUC/, 'UU')
    end

    def short_video?(video)
      duration = video.content_details&.duration
      return false unless duration

      parse_youtube_duration(duration.to_s) <= 60
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
