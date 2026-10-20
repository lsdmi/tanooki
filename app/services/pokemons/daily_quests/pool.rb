# frozen_string_literal: true

require 'digest'

module Pokemons
  module DailyQuests
    # Quest definitions from +config/pokemon_daily_quests.yml+.
    class Pool
      CONFIG_PATH = Rails.root.join('config/pokemon_daily_quests.yml')

      def self.config
        @config ||= YAML.safe_load_file(CONFIG_PATH).to_h
      end

      def self.reload!
        @config = YAML.safe_load_file(CONFIG_PATH).to_h
      end

      def self.pick
        config.fetch('pick', 3).to_i.clamp(1, 10)
      end

      def self.definitions
        config.fetch('quests')
      end

      def self.fetch(key)
        definitions.fetch(key.to_s)
      end

      # Stable three keys for a user on a Kiev date (shuffle seeded by user + day).
      def self.pick_keys(user_id:, on:)
        seed = Digest::SHA256.hexdigest("#{user_id}:#{on.iso8601}").to_i(16) % (2**31)
        definitions.keys.sample(pick, random: Random.new(seed))
      end

      def self.matches?(definition, event:, types: [], genre_slugs: [])
        return false unless definition.fetch('event').to_s == event.to_s
        return false unless need_met?(definition['type'], types)
        return false unless need_met?(definition['genre'], genre_slugs)

        true
      end

      def self.need_met?(need, values)
        need.blank? || Array(values).map(&:to_s).include?(need.to_s)
      end
      private_class_method :need_met?
    end
  end
end
