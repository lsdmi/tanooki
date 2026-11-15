# frozen_string_literal: true

module Root
  # Home «Популярні Відео»: last-month by views, padded with newest so the block
  # always has featured + 3 supporting when enough videos exist.
  class HomeVideos
    CACHE_KEY = 'home_videos/v2'
    CACHE_TTL = 12.hours

    def self.call
      new.call
    end

    def call
      ids = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { select_ids }
      load_videos(ids)
    end

    private

    def limit
      VideosHelper::HOME_VIDEO_LIMIT
    end

    def base_scope
      YoutubeVideo.one_per_video
    end

    def select_ids
      ids = base_scope.last_month.order(views: :desc).limit(limit).pluck(:id)
      return ids if ids.size >= limit

      ids + newest_ids_except(ids, limit - ids.size)
    end

    def newest_ids_except(ids, count)
      base_scope.where.not(id: ids).order(published_at: :desc).limit(count).pluck(:id)
    end

    def load_videos(ids)
      videos = YoutubeVideo.where(id: ids).order(views: :desc).to_a
      return videos if videos.size >= limit

      needed = limit - videos.size
      filler = base_scope.where.not(id: videos.map(&:id)).order(published_at: :desc).limit(needed).to_a
      videos + filler
    end
  end
end
