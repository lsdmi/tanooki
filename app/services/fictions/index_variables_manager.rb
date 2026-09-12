# frozen_string_literal: true

module Fictions
  # Cached fiction lists and badge ids for the fictions index.
  class IndexVariablesManager
    include IndexCachedLists
    include IndexGenreLists

    POPULAR_NOVELTY_CACHE_EXPIRY = 24.hours
    MOST_READS_CACHE_EXPIRY = 24.hours
    LATEST_UPDATES_CACHE_EXPIRY = 10.minutes
    LATEST_UPDATES_INDEX_CARDS = 6
    LATEST_UPDATES_HOME_LIMIT = 8
    MOST_READS_INDEX_CARDS = 10
    POPULAR_NOVELTY_INDEX_CARDS = 13
    # Candidate window the novelty ranking draws from; must exceed the card count so all slots can fill.
    POPULAR_NOVELTY_POOL = 20
    ORIGINALS_CACHE_EXPIRY = 30.minutes
    ORIGINALS_INDEX_CARDS = 8
    FANFICTION_CACHE_EXPIRY = 30.minutes
    FANFICTION_INDEX_CARDS = 10
    GENRE_SPOTLIGHT_CACHE_EXPIRY = 24.hours
    GENRE_SPOTLIGHT_INDEX_CARDS = 11
    GENRE_SPOTLIGHT_COVERS = 3

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

    def self.genre_spotlight
      IndexGenreSpotlight.call
    end
  end
end
