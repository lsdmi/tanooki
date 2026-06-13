# frozen_string_literal: true

module Fictions
  # Cached fiction lists and badge ids for the fictions index.
  class IndexVariablesManager
    LIST_CACHE_EXPIRY = 12.hours
    LATEST_UPDATES_CACHE_EXPIRY = 1.hour
    FILTERED_CACHE_EXPIRY = 12.hours

    def self.popular_novelty
      load_fictions_by_cached_ids(cached_popular_novelty_ids, includes: %i[cover_attachment])
    end

    def self.popular_novelty_ids_for_badges
      Set.new(cached_popular_novelty_ids)
    end

    def self.popular_novelty_scope
      Fiction.joins(:readings)
             .group(:id)
             .where(id: recent_fiction_ids)
             .order('COUNT(reading_progresses.fiction_id) DESC')
             .limit(8)
    end

    def self.cached_popular_novelty_ids
      Rails.cache.fetch('popular_novelty_ids', expires_in: LIST_CACHE_EXPIRY) do
        popular_novelty_scope.pluck(:id)
      end
    end
    private_class_method :cached_popular_novelty_ids

    private_class_method :popular_novelty_scope

    def self.recent_fiction_ids
      Fiction.order(id: :desc).limit(15).pluck(:id)
    end
    private_class_method :recent_fiction_ids

    def self.most_reads
      load_fictions_by_cached_ids(
        cached_most_reads_ids,
        includes: %i[cover_attachment genres fiction_ratings]
      )
    end

    def self.most_reads_ids_for_badges
      Set.new(cached_most_reads_ids)
    end

    def self.most_reads_scope
      Fiction.most_reads.limit(6)
    end

    def self.cached_most_reads_ids
      Rails.cache.fetch('most_reads_ids', expires_in: LIST_CACHE_EXPIRY) do
        most_reads_scope.pluck(:id)
      end
    end
    private_class_method :cached_most_reads_ids

    private_class_method :most_reads_scope

    def self.latest_updates_ranked
      Fiction
        .joins(:chapters)
        .merge(Chapter.released)
        .group('fictions.id')
        .order(Arel.sql("MAX(#{Chapter::PUBLIC_TIME_SQL}) DESC"))
        .limit(9)
    end
    private_class_method :latest_updates_ranked

    def self.latest_updates
      load_fictions_by_cached_ids(
        cached_latest_updates_ids,
        includes: %i[cover_attachment genres]
      )
    end

    def self.latest_updates_ids_for_badges
      Set.new(cached_latest_updates_ids)
    end

    def self.cached_latest_updates_ids
      Rails.cache.fetch('latest_updates_ids', expires_in: LATEST_UPDATES_CACHE_EXPIRY) do
        latest_updates_ranked.pluck(:id)
      end
    end
    private_class_method :cached_latest_updates_ids

    def self.filtered_by_genre(genre)
      return Fiction.none unless genre

      load_fictions_by_cached_ids(
        cached_filtered_fiction_ids(genre.id),
        includes: %i[cover_attachment]
      )
    end

    def self.cached_filtered_fiction_ids(genre_id)
      Rails.cache.fetch(['fiction_index/filtered_fiction_ids', genre_id], expires_in: FILTERED_CACHE_EXPIRY) do
        filtered_fiction_ids_for_genre(genre_id)
      end
    end
    private_class_method :cached_filtered_fiction_ids

    def self.filtered_fiction_ids_for_genre(genre_id)
      fictions_joined_to_latest_released_chapter
        .where(genres: { id: genre_id })
        .order('latest_chapters.max_created_at DESC')
        .limit(8)
        .pluck(:id)
    end
    private_class_method :filtered_fiction_ids_for_genre

    def self.fictions_joined_to_latest_released_chapter
      Fiction.joins(:genres)
             .joins(
               "INNER JOIN (#{Chapter.released
                 .select('fiction_id, MAX(COALESCE(published_at, created_at)) AS max_created_at')
                 .group(:fiction_id)
                 .to_sql}) AS latest_chapters ON latest_chapters.fiction_id = fictions.id"
             )
    end
    private_class_method :fictions_joined_to_latest_released_chapter

    def self.load_fictions_by_cached_ids(ids, includes:)
      return Fiction.none if ids.blank?

      Fiction.where(id: ids)
             .includes(includes)
             .in_order_of(:id, ids)
    end
    private_class_method :load_fictions_by_cached_ids

    def self.warm_index_caches!
      cached_popular_novelty_ids
      cached_most_reads_ids
      cached_latest_updates_ids
      popular_novelty_ids_for_badges
      most_reads_ids_for_badges
      latest_updates_ids_for_badges
      IndexShowcase.for_index
      IndexHotUpdates.fictions
      IndexHotUpdates.counts

      Genre.order(:name).pluck(:id).each do |genre_id|
        cached_filtered_fiction_ids(genre_id)
      end
    end

    def self.genre_recent_updates_excluding(genre, exclude_ids: [])
      base = Fiction.joins(:genres, :chapters).where(genres: { id: genre.id }).merge(Chapter.released)
      base = base.where.not(id: exclude_ids) if exclude_ids.present?
      ranked = base.select("fictions.id, MAX(#{Chapter::PUBLIC_TIME_SQL}) AS genre_sort_at").group('fictions.id')
      Fiction.includes(:cover_attachment, :fiction_ratings)
             .joins("INNER JOIN (#{ranked.to_sql}) AS genre_recent_agg ON genre_recent_agg.id = fictions.id")
             .order(Arel.sql('genre_recent_agg.genre_sort_at DESC'))
    end

    def self.hot_updates
      IndexHotUpdates.fictions
    end

    def self.hot_updates_counts
      IndexHotUpdates.counts
    end

    def self.showcase
      IndexShowcase.for_index
    end

    def self.showcase_for_genre(genre)
      IndexShowcase.for_genre(genre)
    end
  end
end
