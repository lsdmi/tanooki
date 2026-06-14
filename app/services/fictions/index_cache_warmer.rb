# frozen_string_literal: true

module Fictions
  # Preloads fiction index cache keys used by the homepage and warm job.
  class IndexCacheWarmer
    def self.call
      warm_list_caches
      warm_genre_caches
    end

    def self.warm_list_caches
      IndexVariablesManager.send(:cached_popular_novelty_ids)
      IndexVariablesManager.send(:cached_most_reads_ids)
      IndexVariablesManager.send(:cached_latest_updates_ids)
      IndexVariablesManager.popular_novelty_ids_for_badges
      IndexVariablesManager.most_reads_ids_for_badges
      IndexVariablesManager.latest_updates_ids_for_badges
      IndexShowcase.for_index
      IndexHotUpdates.fictions
      IndexHotUpdates.counts
    end

    def self.warm_genre_caches
      Genre.order(:name).pluck(:id).each do |genre_id|
        IndexVariablesManager.send(:cached_filtered_fiction_ids, genre_id)
      end
    end
  end
end
