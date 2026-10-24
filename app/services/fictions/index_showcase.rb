# frozen_string_literal: true

module Fictions
  # Homepage / genre carousel: cache sampled fiction ids, then load rows with banner + ratings preloads.
  # Licensed works never get a slide: the carousel promotes reading here, and the cached ids can outlive a
  # license, so the load filters again.
  class IndexShowcase
    CACHE_KEY = 'fiction_showcase_ids'
    INDEX_CACHE_EXPIRY = 1.hour
    GENRE_CACHE_EXPIRY = 12.hours
    CARD_LIMIT = 5
    SAMPLE_SIZE = CARD_LIMIT * 2

    def self.for_index(filter: ContentFilters::Preference.open)
      ids = Rails.cache.fetch(CACHE_KEY, expires_in: INDEX_CACHE_EXPIRY) { random_sample_index }
      load_fictions(ids, filter)
    end

    def self.for_genre(genre, filter: ContentFilters::Preference.open)
      ids = Rails.cache.fetch(['fiction_showcase_genre', genre.id], expires_in: GENRE_CACHE_EXPIRY) do
        random_sample_for_genre(genre)
      end
      load_fictions(ids, filter)
    end

    class << self
      private

      def id_pool
        (
          IndexVariablesManager.latest_updates_ids_for_badges.to_a +
          IndexVariablesManager.most_reads_ids_for_badges.to_a +
          IndexVariablesManager.popular_novelty_ids_for_badges.to_a
        ).uniq
      end

      def random_sample_index
        Fiction
          .not_licensed
          .where(id: id_pool)
          .where.not(short_description: [nil, ''])
          .joins(:banner_attachment)
          .distinct
          .pluck(:id)
          .sample(SAMPLE_SIZE)
      end

      def random_sample_for_genre(genre)
        Fiction
          .not_licensed
          .where(id: id_pool)
          .where.not(short_description: [nil, ''])
          .joins(:genres, :banner_attachment)
          .where(genres: { id: genre.id })
          .distinct
          .pluck(:id)
          .sample(SAMPLE_SIZE)
      end

      def load_fictions(ids, filter)
        return Fiction.none if ids.blank?

        filter.apply(
          Fiction.not_licensed
                 .where(id: ids)
                 .includes(:fiction_ratings, :banner_attachment)
                 .in_order_of(:id, ids)
        ).limit(CARD_LIMIT)
      end
    end
  end
end
