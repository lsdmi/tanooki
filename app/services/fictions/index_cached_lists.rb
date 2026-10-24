# frozen_string_literal: true

module Fictions
  # Cached popular, most-read, and latest-update lists for the fictions index.
  module IndexCachedLists
    def self.included(base)
      base.extend ClassMethods
    end

    def self.expire!
      Rails.cache.delete(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY)
      Rails.cache.delete(IndexVariablesManager::RECENT_FICTION_IDS_CACHE_KEY)
      Rails.cache.delete(IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY)
      Rails.cache.delete(IndexVariablesManager.most_reads_ids_cache_key)
    end

    # Class methods mixed into IndexVariablesManager.
    module ClassMethods
      def popular_novelty(filter: ContentFilters::Preference.open)
        load_fictions_by_cached_ids(cached_popular_novelty_ids,
                                    includes: %i[cover_attachment],
                                    filter:,
                                    limit: IndexVariablesManager::POPULAR_NOVELTY_INDEX_CARDS)
      end

      def popular_novelty_ids_for_badges
        Set.new(cached_recent_fiction_ids)
      end

      def popular_novelty_featured_chapter_count
        popular_novelty_featured_chapter_count_for(cached_popular_novelty_ids.first)
      end

      def popular_novelty_featured_chapter_count_for(fiction_id)
        return 0 if fiction_id.blank?

        Rails.cache.fetch(
          IndexVariablesManager.popular_novelty_featured_chapter_count_cache_key(fiction_id),
          expires_in: IndexVariablesManager::POPULAR_NOVELTY_CACHE_EXPIRY
        ) do
          Chapter.released.where(fiction_id:).count
        end
      end

      def most_reads(filter: ContentFilters::Preference.open)
        load_fictions_by_cached_ids(cached_most_reads_ids,
                                    includes: %i[cover_attachment genres fiction_ratings],
                                    filter:,
                                    limit: IndexVariablesManager::MOST_READS_INDEX_CARDS)
      end

      def most_reads_ids_for_badges
        Set.new(cached_most_reads_ids)
      end

      def latest_updates(filter: ContentFilters::Preference.open)
        load_fictions_by_cached_ids(cached_latest_updates_ids,
                                    includes: %i[cover_attachment],
                                    filter:,
                                    limit: IndexVariablesManager::LATEST_UPDATES_INDEX_CARDS)
      end

      def latest_updates_for_homepage(filter: ContentFilters::Preference.open)
        load_fictions_by_cached_ids(cached_latest_updates_ids,
                                    includes: %i[cover_attachment],
                                    filter:,
                                    limit: IndexVariablesManager::LATEST_UPDATES_HOME_LIMIT)
      end

      def latest_updates_ids_for_badges
        Set.new(cached_latest_updates_ids)
      end

      private

      def popular_novelty_scope
        Fiction.joins(:readings)
               .group(:id)
               .where(id: cached_recent_fiction_ids)
               .order('COUNT(reading_progresses.fiction_id) DESC')
               .limit(IndexVariablesManager.pool_size)
      end

      def cached_popular_novelty_ids
        Rails.cache.fetch(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY,
                          expires_in: IndexVariablesManager::POPULAR_NOVELTY_CACHE_EXPIRY) do
          ids = popular_novelty_scope.pluck(:id)
          popular_novelty_featured_chapter_count_for(ids.first)
          ids
        end
      end

      def cached_recent_fiction_ids
        limit = IndexVariablesManager.pool_size
        Rails.cache.fetch(IndexVariablesManager::RECENT_FICTION_IDS_CACHE_KEY,
                          expires_in: IndexVariablesManager::POPULAR_NOVELTY_CACHE_EXPIRY) do
          Fiction.order(id: :desc).limit(limit).pluck(:id)
        end
      end

      def most_reads_scope
        Fiction.most_reads.limit(IndexVariablesManager.pool_size)
      end

      def cached_most_reads_ids
        Rails.cache.fetch(
          IndexVariablesManager.most_reads_ids_cache_key,
          expires_in: IndexVariablesManager::MOST_READS_CACHE_EXPIRY
        ) do
          most_reads_scope.pluck(:id)
        end
      end

      def latest_updates_ranked
        Fiction
          .joins(:chapters)
          .merge(Chapter.released)
          .group('fictions.id')
          .order(Arel.sql("MAX(#{Chapter::PUBLIC_TIME_SQL}) DESC"))
          .limit(IndexVariablesManager.pool_size)
      end

      def cached_latest_updates_ids
        Rails.cache.fetch(IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY,
                          expires_in: IndexVariablesManager::LATEST_UPDATES_CACHE_EXPIRY) do
          latest_updates_ranked.pluck(:id)
        end
      end

      def load_fictions_by_cached_ids(ids, includes:, filter: ContentFilters::Preference.open, limit: nil)
        return Fiction.none if ids.blank?

        scope = filter.apply(Fiction.where(id: ids)).preload(includes).in_order_of(:id, ids)
        scope = scope.limit(limit) if limit
        scope
      end
    end
  end
end
