# frozen_string_literal: true

module Fictions
  # Preloads fiction index cache keys used by the homepage and warm job.
  class IndexCacheWarmer
    def self.call
      warm_list_caches
      warm_genre_caches
    end

    def self.warm_list_caches
      warm_cached_list_ids
      warm_badge_and_side_caches
    end

    def self.warm_genre_caches
      Genre.order(:name).pluck(:id).each do |genre_id|
        IndexVariablesManager.send(:cached_filtered_fiction_ids, genre_id)
      end
    end

    def self.warm_cached_list_ids
      %i[
        cached_popular_novelty_ids
        cached_most_reads_ids
        cached_latest_updates_ids
        cached_originals_ids
        cached_fanfiction_ids
      ].each { |method| IndexVariablesManager.send(method) }
    end
    private_class_method :warm_cached_list_ids

    def self.warm_badge_and_side_caches
      IndexVariablesManager.popular_novelty_ids_for_badges
      IndexVariablesManager.most_reads_ids_for_badges
      IndexVariablesManager.latest_updates_ids_for_badges
      IndexShowcase.for_index
      IndexHotUpdates.fictions
      IndexHotUpdates.counts
    end
    private_class_method :warm_badge_and_side_caches
  end
end
