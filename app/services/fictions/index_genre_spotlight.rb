# frozen_string_literal: true

module Fictions
  # Ranked genre tiles for the fictions index: latest chapter activity + unique covers.
  class IndexGenreSpotlight
    Entry = Data.define(:genre, :fictions, :fictions_count)

    COVER_CANDIDATE_POOL = 30

    def self.call(filter: ContentFilters::Preference.open)
      new(filter).call
    end

    def self.warm!
      cached_payload
    end

    def self.cache_key
      [
        'fiction_index/genre_spotlight',
        IndexVariablesManager::GENRE_SPOTLIGHT_INDEX_CARDS,
        IndexVariablesManager::GENRE_SPOTLIGHT_COVERS,
        IndexVariablesManager::CANDIDATE_POOL
      ]
    end

    def self.cached_payload
      Rails.cache.fetch(cache_key, expires_in: IndexVariablesManager::GENRE_SPOTLIGHT_CACHE_EXPIRY) do
        payload_from_db
      end
    end

    def self.payload_from_db
      new.send(:build_payload)
    end

    def initialize(filter = ContentFilters::Preference.open)
      @filter = filter
    end

    def call
      payload = self.class.cached_payload
      return [] if payload.blank?

      hydrate(payload).first(IndexVariablesManager::GENRE_SPOTLIGHT_INDEX_CARDS)
    end

    private

    def build_payload
      genre_ids = ranked_genre_ids
      return [] if genre_ids.blank?

      counts = FictionGenre.where(genre_id: genre_ids).group(:genre_id).count
      claimed = Set.new

      genre_ids.filter_map do |genre_id|
        fiction_ids = unique_cover_ids_for(genre_id, claimed)
        next if fiction_ids.empty?

        { genre_id:, fiction_ids:, fictions_count: counts.fetch(genre_id, 0) }
      end
    end

    def ranked_genre_ids
      excluded = Genre.where(slug: [Genre::ORIGINAL_SLUG, Genre::FANFICTION_SLUG]).pluck(:id)

      scope = Genre.joins(fictions: :chapters).merge(Chapter.released)
      scope = scope.where.not(id: excluded) if excluded.any?

      scope.group('genres.id')
           .order(Arel.sql("MAX(#{Chapter::PUBLIC_TIME_SQL}) DESC"))
           .limit(IndexVariablesManager.pool_size)
           .pluck('genres.id')
    end

    # Claim only the covers an open reader sees. Extras stay unclaimed so a filter can refill a tile
    # without changing the open catalogue's cover sets.
    def unique_cover_ids_for(genre_id, claimed)
      covers = IndexVariablesManager::GENRE_SPOTLIGHT_COVERS
      candidates = IndexVariablesManager.send(:recent_fiction_ids_for_genre_id, genre_id, COVER_CANDIDATE_POOL)
      available = candidates.reject { |id| claimed.include?(id) }
      shown = available.first(covers)
      claimed.merge(shown)
      shown + available.drop(covers).first(covers)
    end

    def hydrate(payload)
      genres_by_id = Genre.where(id: payload.pluck(:genre_id)).index_by(&:id)
      fictions_by_id = spotlight_fictions_by_id(payload)

      payload.filter_map { |row| hydrate_entry(row, genres_by_id, fictions_by_id) }
    end

    def spotlight_fictions_by_id(payload)
      ids = payload.flat_map { |row| row[:fiction_ids] }
      return {} if ids.empty?

      @filter.apply(Fiction.where(id: ids).preload(:cover_attachment)).index_by(&:id)
    end

    def hydrate_entry(row, genres_by_id, fictions_by_id)
      genre = genres_by_id[row[:genre_id]]
      return unless genre

      fictions = row[:fiction_ids].filter_map { |id| fictions_by_id[id] }
      fictions = fictions.first(IndexVariablesManager::GENRE_SPOTLIGHT_COVERS)
      return if fictions.empty?

      Entry.new(genre:, fictions:, fictions_count: row[:fictions_count])
    end
  end
end
