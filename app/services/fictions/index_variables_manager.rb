# frozen_string_literal: true

module Fictions
  # Cached fiction lists and badge ids for the fictions index.
  class IndexVariablesManager
    include IndexCachedLists
    include IndexGenreLists

    LIST_CACHE_EXPIRY = 12.hours
    LATEST_UPDATES_CACHE_EXPIRY = 1.hour
    FILTERED_CACHE_EXPIRY = 12.hours

    def self.warm_index_caches!
      IndexCacheWarmer.call
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
