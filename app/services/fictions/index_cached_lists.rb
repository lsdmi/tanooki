# frozen_string_literal: true

module Fictions
  # Cached popular, most-read, and latest-update lists for the fictions index.
  module IndexCachedLists
    def self.included(base)
      base.extend ClassMethods
    end

    # Class methods mixed into IndexVariablesManager.
    module ClassMethods
      def popular_novelty
        load_fictions_by_cached_ids(cached_popular_novelty_ids, includes: %i[cover_attachment])
      end

      def popular_novelty_ids_for_badges
        Set.new(cached_popular_novelty_ids)
      end

      def most_reads
        load_fictions_by_cached_ids(
          cached_most_reads_ids,
          includes: %i[cover_attachment genres fiction_ratings]
        )
      end

      def most_reads_ids_for_badges
        Set.new(cached_most_reads_ids)
      end

      def latest_updates
        load_fictions_by_cached_ids(
          cached_latest_updates_ids,
          includes: %i[cover_attachment genres]
        )
      end

      def latest_updates_ids_for_badges
        Set.new(cached_latest_updates_ids)
      end

      private

      def popular_novelty_scope
        Fiction.joins(:readings)
               .group(:id)
               .where(id: recent_fiction_ids)
               .order('COUNT(reading_progresses.fiction_id) DESC')
               .limit(8)
      end

      def cached_popular_novelty_ids
        Rails.cache.fetch('popular_novelty_ids', expires_in: IndexVariablesManager::LIST_CACHE_EXPIRY) do
          popular_novelty_scope.pluck(:id)
        end
      end

      def recent_fiction_ids
        Fiction.order(id: :desc).limit(15).pluck(:id)
      end

      def most_reads_scope
        Fiction.most_reads.limit(6)
      end

      def cached_most_reads_ids
        Rails.cache.fetch('most_reads_ids', expires_in: IndexVariablesManager::LIST_CACHE_EXPIRY) do
          most_reads_scope.pluck(:id)
        end
      end

      def latest_updates_ranked
        Fiction
          .joins(:chapters)
          .merge(Chapter.released)
          .group('fictions.id')
          .order(Arel.sql("MAX(#{Chapter::PUBLIC_TIME_SQL}) DESC"))
          .limit(9)
      end

      def cached_latest_updates_ids
        Rails.cache.fetch('latest_updates_ids', expires_in: IndexVariablesManager::LATEST_UPDATES_CACHE_EXPIRY) do
          latest_updates_ranked.pluck(:id)
        end
      end

      def load_fictions_by_cached_ids(ids, includes:)
        return Fiction.none if ids.blank?

        Fiction.where(id: ids)
               .includes(includes)
               .in_order_of(:id, ids)
      end
    end
  end
end
