# frozen_string_literal: true

module Fictions
  # Cached fiction lists and badge ids for the fictions index.
  class IndexVariablesManager
    include IndexCachedLists
    include IndexGenreLists

    POPULAR_NOVELTY_CACHE_EXPIRY = 24.hours
    CANDIDATE_POOL = 50
    POPULAR_NOVELTY_IDS_CACHE_KEY = "popular_novelty_ids/#{CANDIDATE_POOL}".freeze
    RECENT_FICTION_IDS_CACHE_KEY = "recent_fiction_ids/#{CANDIDATE_POOL}".freeze
    POPULAR_NOVELTY_FEATURED_CHAPTER_COUNT_CACHE_KEY = 'popular_novelty_featured_chapter_count'
    MOST_READS_CACHE_EXPIRY = 24.hours
    LATEST_UPDATES_CACHE_EXPIRY = 10.minutes
    LATEST_UPDATES_IDS_CACHE_KEY = "latest_updates_ids/#{CANDIDATE_POOL}".freeze
    LATEST_UPDATES_INDEX_CARDS = 6
    LATEST_UPDATES_HOME_LIMIT = 8
    MOST_READS_INDEX_CARDS = 10
    POPULAR_NOVELTY_INDEX_CARDS = 13
    ORIGINALS_CACHE_EXPIRY = 30.minutes
    ORIGINALS_INDEX_CARDS = 8
    FANFICTION_CACHE_EXPIRY = 30.minutes
    FANFICTION_INDEX_CARDS = 10
    GENRE_SPOTLIGHT_CACHE_EXPIRY = 24.hours
    GENRE_SPOTLIGHT_INDEX_CARDS = 11
    GENRE_SPOTLIGHT_COVERS = 3

    # Shared caches keep this many candidates so a filtered rail can refill the visible row.
    # Display still slices to the card count.
    def self.pool_size
      CANDIDATE_POOL
    end

    def self.most_reads_ids_cache_key
      ['most_reads_ids', MOST_READS_INDEX_CARDS, CANDIDATE_POOL]
    end

    def self.originals_ids_cache_key
      ['fiction_index/originals_ids', ORIGINALS_INDEX_CARDS, CANDIDATE_POOL]
    end

    def self.fanfiction_ids_cache_key
      ['fiction_index/fanfiction_ids', FANFICTION_INDEX_CARDS, CANDIDATE_POOL]
    end

    # The unfiltered head of a cached rail, same length as the cards it shows.
    def self.pool_head(key, limit)
      ids = case key.to_sym
            when :latest_updates then cached_latest_updates_ids
            when :most_reads then cached_most_reads_ids
            when :popular_novelty then cached_popular_novelty_ids
            when :originals then cached_originals_ids
            when :fanfictions then cached_fanfiction_ids
            else []
            end
      Array(ids).first(limit)
    end

    def self.warm_index_caches!
      IndexCacheWarmer.call
    end

    def self.hot_updates(filter: ContentFilters::Preference.open)
      IndexHotUpdates.fictions(filter:)
    end

    def self.hot_updates_counts
      IndexHotUpdates.counts
    end

    def self.showcase(filter: ContentFilters::Preference.open)
      IndexShowcase.for_index(filter:)
    end

    def self.showcase_for_genre(genre, filter: ContentFilters::Preference.open)
      IndexShowcase.for_genre(genre, filter:)
    end

    def self.genre_spotlight(filter: ContentFilters::Preference.open)
      IndexGenreSpotlight.call(filter:)
    end

    def self.cache_hit_snapshot
      featured_id = Array(Rails.cache.read(POPULAR_NOVELTY_IDS_CACHE_KEY)).first

      {
        showcase: Rails.cache.exist?(IndexShowcase::CACHE_KEY),
        latest_updates: Rails.cache.exist?(LATEST_UPDATES_IDS_CACHE_KEY),
        most_reads: Rails.cache.exist?(['most_reads_ids', MOST_READS_INDEX_CARDS, CANDIDATE_POOL]),
        popular_novelty: Rails.cache.exist?(POPULAR_NOVELTY_IDS_CACHE_KEY),
        featured_chapter_count: featured_id.present? &&
          Rails.cache.exist?(popular_novelty_featured_chapter_count_cache_key(featured_id))
      }
    end

    def self.http_cache_fingerprint
      [
        Rails.cache.read(POPULAR_NOVELTY_IDS_CACHE_KEY),
        Rails.cache.read(LATEST_UPDATES_IDS_CACHE_KEY),
        Rails.cache.read(['most_reads_ids', MOST_READS_INDEX_CARDS, CANDIDATE_POOL]),
        Rails.cache.read(IndexShowcase::CACHE_KEY),
        Rails.cache.read(['fiction_index/originals_ids', ORIGINALS_INDEX_CARDS, CANDIDATE_POOL]),
        Rails.cache.read(['fiction_index/fanfiction_ids', FANFICTION_INDEX_CARDS, CANDIDATE_POOL]),
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
