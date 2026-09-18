# frozen_string_literal: true

module Root
  # Card assembly for the home page «Популярні Відео» editorial layout.
  module VideosHelper
    SUPPORTING_VIDEO_COUNT = 3
    HOME_VIDEO_LIMIT = SUPPORTING_VIDEO_COUNT + 1
    FEATURED_TAG_LIMIT = 3
    NARROW_FEATURED_TAG_LIMIT = 1
    TABLET_FEATURED_TAG_LIMIT = 2
    COMPACT_TAG_LIMIT = 2
    YOUTUBE_THUMB_PATH = %r{\Ahttps?://(?:i(?:mg)?\.ytimg\.com|img\.youtube\.com)/vi/}i
    MAXRES_POSTER = 'maxresdefault.jpg'
    SD_POSTER = 'sddefault.jpg'

    def home_videos_editorial_cards(videos)
      ordered = videos.to_a
      return { featured: nil, supporting: [] } if ordered.empty?

      { featured: ordered.first, supporting: ordered.drop(1).first(SUPPORTING_VIDEO_COUNT) }
    end

    def home_video_tag_labels(video)
      Search::TagCounts.labels_from_youtube_video(video, limit: Search::TagCounts::HOME_YOUTUBE_TAG_LIMIT)
    end

    # 16:9 maxres poster — hq/sd YouTube thumbs are 4:3 with letterbox bars.
    def home_featured_video_poster_url(video)
      thumbnail = video.thumbnail.to_s
      if thumbnail.blank? || thumbnail.match?(YOUTUBE_THUMB_PATH)
        return youtube_poster_url(video.video_id, MAXRES_POSTER)
      end

      thumbnail
    end

    def home_featured_video_fallback_poster_url(video)
      youtube_poster_url(video.video_id, SD_POSTER)
    end

    private

    def youtube_poster_url(video_id, filename)
      "https://i.ytimg.com/vi/#{video_id}/#{filename}"
    end
  end
end
