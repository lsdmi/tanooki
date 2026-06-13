# frozen_string_literal: true

module Fictions
  # Homepage / genre carousel: cache sampled fiction ids, then load rows with banner + ratings preloads.
  class IndexShowcase
    CACHE_KEY = 'fiction_showcase_ids'
    INDEX_CACHE_EXPIRY = 1.hour
    GENRE_CACHE_EXPIRY = 12.hours

    def self.for_index
      ids = Rails.cache.fetch(CACHE_KEY, expires_in: INDEX_CACHE_EXPIRY) { random_sample_index }
      return Fiction.none if ids.blank?

      load_fictions(ids)
    end

    def self.for_genre(genre)
      ids = Rails.cache.fetch(['fiction_showcase_genre', genre.id], expires_in: GENRE_CACHE_EXPIRY) do
        random_sample_for_genre(genre)
      end
      return Fiction.none if ids.blank?

      load_fictions(ids)
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
          .where(id: id_pool)
          .where.not(short_description: [nil, ''])
          .joins(:banner_attachment)
          .distinct
          .pluck(:id)
          .sample(5)
      end

      def random_sample_for_genre(genre)
        Fiction
          .where(id: id_pool)
          .where.not(short_description: [nil, ''])
          .joins(:genres, :banner_attachment)
          .where(genres: { id: genre.id })
          .distinct
          .pluck(:id)
          .sample(5)
      end

      def load_fictions(ids)
        Fiction
          .where(id: ids)
          .includes(:fiction_ratings, :banner_attachment)
          .in_order_of(:id, ids)
      end
    end
  end
end
