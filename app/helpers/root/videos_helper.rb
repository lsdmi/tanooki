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

    def home_videos_editorial_cards(videos)
      ordered = videos.to_a
      return { featured: nil, supporting: [] } if ordered.empty?

      { featured: ordered.first, supporting: ordered.drop(1).first(SUPPORTING_VIDEO_COUNT) }
    end

    def home_video_tag_labels(video)
      Search::TagCounts.labels_from_youtube_video(video, limit: Search::TagCounts::HOME_YOUTUBE_TAG_LIMIT)
    end
  end
end
