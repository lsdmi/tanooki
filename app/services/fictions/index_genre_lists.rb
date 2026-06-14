# frozen_string_literal: true

module Fictions
  # Genre-filtered fiction lists for the fictions index.
  module IndexGenreLists
    def self.included(base)
      base.extend ClassMethods
    end

    # Class methods mixed into IndexVariablesManager.
    module ClassMethods
      def filtered_by_genre(genre)
        return Fiction.none unless genre

        load_fictions_by_cached_ids(
          cached_filtered_fiction_ids(genre.id),
          includes: %i[cover_attachment]
        )
      end

      def genre_recent_updates_excluding(genre, exclude_ids: [])
        base = Fiction.joins(:genres, :chapters).where(genres: { id: genre.id }).merge(Chapter.released)
        base = base.where.not(id: exclude_ids) if exclude_ids.present?
        ranked = base.select("fictions.id, MAX(#{Chapter::PUBLIC_TIME_SQL}) AS genre_sort_at").group('fictions.id')
        Fiction.includes(:cover_attachment, :fiction_ratings)
               .joins("INNER JOIN (#{ranked.to_sql}) AS genre_recent_agg ON genre_recent_agg.id = fictions.id")
               .order(Arel.sql('genre_recent_agg.genre_sort_at DESC'))
      end

      private

      def cached_filtered_fiction_ids(genre_id)
        Rails.cache.fetch(['fiction_index/filtered_fiction_ids', genre_id],
                          expires_in: IndexVariablesManager::FILTERED_CACHE_EXPIRY) do
          filtered_fiction_ids_for_genre(genre_id)
        end
      end

      def filtered_fiction_ids_for_genre(genre_id)
        fictions_joined_to_latest_released_chapter
          .where(genres: { id: genre_id })
          .order('latest_chapters.max_created_at DESC')
          .limit(8)
          .pluck(:id)
      end

      def fictions_joined_to_latest_released_chapter
        Fiction.joins(:genres)
               .joins(
                 "INNER JOIN (#{Chapter.released
                   .select('fiction_id, MAX(COALESCE(published_at, created_at)) AS max_created_at')
                   .group(:fiction_id)
                   .to_sql}) AS latest_chapters ON latest_chapters.fiction_id = fictions.id"
               )
      end
    end
  end
end
