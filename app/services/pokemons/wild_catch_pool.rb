# frozen_string_literal: true

module Pokemons
  # Cached rarity-weighted Pokemon id pool for wild encounters (avoids per-catch find_each).
  # Optional +boost_types+ (habitat) multiply the weight of matching wild species.
  class WildCatchPool
    RARITY_WEIGHTS = {
      1 => 27,
      2 => 9,
      3 => 3,
      4 => 1
    }.freeze

    CACHE_KEY_PREFIX = 'pokemons/wild_catch_weighted_ids/v3'

    class << self
      def sample_id(boost_types: nil)
        weighted_ids(boost_types:).sample
      end

      def weighted_ids(boost_types: nil)
        types = normalize_types(boost_types)
        return base_weighted_ids if types.empty?

        Rails.cache.fetch(boost_cache_key(types), expires_in: 24.hours) { build_weighted_ids(boost_types: types) }
      end

      def cache_key
        "#{CACHE_KEY_PREFIX}/#{Pokemon.maximum(:updated_at).to_i}/#{Pokemon.count}"
      end

      private

      def base_weighted_ids
        Rails.cache.fetch(cache_key, expires_in: 24.hours) { build_weighted_ids }
      end

      def boost_cache_key(types)
        "#{cache_key}/boost/#{types.join('-')}/x#{Habitat.boost}"
      end

      def normalize_types(boost_types)
        Array(boost_types).map(&:to_s).uniq.sort
      end

      # Only first forms are wild; rarity 5 (legendaries) has no weight, so none of them appear.
      def build_weighted_ids(boost_types: [])
        boost = boost_types.present? ? Habitat.boost : 1
        matching = matching_wild_ids(boost_types)
        Pokemon.wild.pluck(:id, :rarity).flat_map do |id, rarity|
          weight = RARITY_WEIGHTS.fetch(rarity, 0)
          weight *= boost if matching.include?(id)
          Array.new(weight, id)
        end
      end

      def matching_wild_ids(boost_types)
        return Set.new if boost_types.blank?

        Pokemon.wild.joins(:pokemon_types).where(pokemon_types: { key: boost_types }).distinct.pluck(:id).to_set
      end
    end
  end
end
