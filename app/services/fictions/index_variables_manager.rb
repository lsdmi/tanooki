# frozen_string_literal: true

module Fictions
  # Cached fiction lists and badge ids for the fictions index.
  class IndexVariablesManager
    include IndexCachedLists
    include IndexGenreLists

    POPULAR_NOVELTY_CACHE_EXPIRY = 24.hours
    POPULAR_NOVELTY_IDS_CACHE_KEY = 'popular_novelty_ids'
    POPULAR_NOVELTY_FEATURED_CHAPTER_COUNT_CACHE_KEY = 'popular_novelty_featured_chapter_count'
    MOST_READS_CACHE_EXPIRY = 24.hours
    LATEST_UPDATES_CACHE_EXPIRY = 10.minutes
    LATEST_UPDATES_IDS_CACHE_KEY = 'latest_updates_ids'
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

    def self.cache_hit_snapshot
      featured_id = Array(Rails.cache.read(POPULAR_NOVELTY_IDS_CACHE_KEY)).first

      {
        showcase: Rails.cache.exist?(IndexShowcase::CACHE_KEY),
        latest_updates: Rails.cache.exist?(LATEST_UPDATES_IDS_CACHE_KEY),
        most_reads: Rails.cache.exist?(['most_reads_ids', MOST_READS_INDEX_CARDS]),
        popular_novelty: Rails.cache.exist?(POPULAR_NOVELTY_IDS_CACHE_KEY),
        featured_chapter_count: featured_id.present? &&
          Rails.cache.exist?(popular_novelty_featured_chapter_count_cache_key(featured_id))
      }
    end

    def self.http_cache_fingerprint
      [
        Rails.cache.read(POPULAR_NOVELTY_IDS_CACHE_KEY),
        Rails.cache.read(LATEST_UPDATES_IDS_CACHE_KEY),
        Rails.cache.read(['most_reads_ids', MOST_READS_INDEX_CARDS]),
        Rails.cache.read(IndexShowcase::CACHE_KEY),
        Rails.cache.read(['fiction_index/originals_ids', ORIGINALS_INDEX_CARDS]),
        Rails.cache.read(['fiction_index/fanfiction_ids', FANFICTION_INDEX_CARDS]),
        Rails.cache.read(IndexGenreSpotlight.cache_key)
      ]
    end

    def self.popular_novelty_featured_chapter_count_cache_key(fiction_id)
      [POPULAR_NOVELTY_FEATURED_CHAPTER_COUNT_CACHE_KEY, fiction_id]
    end

    def self.format_cache_hit_snapshot(snapshot)
      snapshot.map { |name, hit| "#{name}:#{hit ? 'hit' : 'miss'}" }.join(',')
    end
  end
end
