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

    CACHE_KEY_PREFIX = 'pokemons/wild_catch_weighted_ids'

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

      def build_weighted_ids
        Pokemon.pluck(:id, :rarity).flat_map do |id, rarity_value|
          level = rarity_value.is_a?(Integer) ? rarity_value : Pokemon::RARITY_LEVELS[rarity_value]
          weight = RARITY_WEIGHTS[level]
          weight ? Array.new(weight, id) : []
        end
      end
    end
  end
end
