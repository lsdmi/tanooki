# frozen_string_literal: true

module Pokemons
  module Items
    # Item definitions and quest reward weights from +config/pokemon_items.yml+.
    class Catalog
      CONFIG_PATH = Rails.root.join('config/pokemon_items.yml')

      def self.config
        @config ||= YAML.safe_load_file(CONFIG_PATH).to_h
      end

      def self.reload!
        @config = YAML.safe_load_file(CONFIG_PATH).to_h
      end

      def self.quest_candy_reward
        config.fetch('quest_candy_reward', 5).to_i
      end

      def self.items
        config.fetch('items')
      end

      def self.fetch(key)
        items.fetch(key.to_s)
      end

      def self.known?(key)
        items.key?(key.to_s)
      end

      def self.quest_reward_key
        weights = config.fetch('quest_rewards')
        pool = weights.flat_map { |key, weight| [key.to_s] * weight.to_i }
        pool.sample
      end

      def self.usable_keys
        items.keys.reject { |key| fetch(key)['effect'].to_s == 'cosmetic' }
      end
    end
  end
end
