# frozen_string_literal: true

module Pokemons
  # Cached rarity-weighted Pokemon id pool for wild encounters (avoids per-catch find_each).
  class WildCatchPool
    RARITY_WEIGHTS = {
      1 => 27,
      2 => 9,
      3 => 3,
      4 => 1
    }.freeze

    CACHE_KEY_PREFIX = 'pokemons/wild_catch_weighted_ids/v2'

    class << self
      def sample_id
        weighted_ids.sample
      end

      def weighted_ids
        Rails.cache.fetch(cache_key, expires_in: 24.hours) { build_weighted_ids }
      end

      def cache_key
        "#{CACHE_KEY_PREFIX}/#{Pokemon.maximum(:updated_at).to_i}/#{Pokemon.count}"
      end

      private

      # Only first forms are wild; rarity 5 (legendaries) has no weight, so none of them appear.
      def build_weighted_ids
        Pokemon.wild.pluck(:id, :rarity).flat_map do |id, rarity|
          Array.new(RARITY_WEIGHTS.fetch(rarity, 0), id)
        end
      end
    end
  end
end
