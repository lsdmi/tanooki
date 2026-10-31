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

      def self.weekly_streak_days
        (config.dig('weekly_streak', 'days') || 5).to_i.clamp(1, 7)
      end

      def self.weekly_streak_candy_reward
        (config.dig('weekly_streak', 'candy_reward') || 0).to_i
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

      def self.matches?(definition, event:, **filters)
        return false unless definition.fetch('event').to_s == event.to_s

        needs_met?(definition, filters)
      end

      def self.needs_met?(definition, filters)
        return false unless need_met?(definition['type'], filters.fetch(:types, []))
        return false unless need_met?(definition['genre'], filters.fetch(:genre_slugs, []))
        return false if definition['ranked'] && !filters.fetch(:ranked, false)
        return false unless side_met?(definition['side'], filters[:side])

        true
      end
      private_class_method :needs_met?

      def self.need_met?(need, values)
        need.blank? || Array(values).map(&:to_s).include?(need.to_s)
      end
      private_class_method :need_met?

      def self.side_met?(need, side)
        need.blank? || need.to_s == side.to_s
      end
      private_class_method :side_met?
    end
  end
end
