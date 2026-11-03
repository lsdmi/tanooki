# frozen_string_literal: true

module Contests
  # Loads and validates contest format presets from config/contests/presets.yml.
  class Preset
    PATH = Rails.root.join('config/contests/presets.yml')
    KNOWN_NOMINATIONS = %w[readers_choice jury_choice debut continuation].freeze
    Duration = Data.define(:announce, :submissions, :judging)

    class Error < StandardError; end

    attr_reader :key, :data

    def self.all
      raw_catalog.keys.map { |key| new(key) }
    end

    def self.find!(key)
      new(key.to_s)
    end

    def self.raw_catalog
      @raw_catalog ||= YAML.safe_load_file(PATH, aliases: true).deep_stringify_keys
    end

    def initialize(key)
      @key = key.to_s
      @data = self.class.raw_catalog.fetch(@key) do
        raise Error, "unknown preset: #{@key}"
      end
      validate!
    end

    def version = data.fetch('version').to_i
    def kind = data.fetch('kind')
    def required_genre_slug = data['required_genre'].presence
    def jury_weight = data.fetch('jury_weight').to_i
    def criteria = Array(data.fetch('criteria')).map(&:stringify_keys)
    def prize_split = data.fetch('prize_split').transform_keys(&:to_i).transform_values(&:to_i)
    def nominations = Array(data['nominations']).map(&:to_s)
    def donation_goals = Array(data['donation_goals']).map(&:stringify_keys)
    def requirements = data.fetch('requirements').stringify_keys

    def durations
      raw = data.fetch('durations')
      Duration.new(
        announce: parse_duration(raw.fetch('announce')),
        submissions: parse_duration(raw.fetch('submissions')),
        judging: parse_duration(raw.fetch('judging'))
      )
    end

    def required_genre
      slug = required_genre_slug
      return if slug.blank?

      Genre.find_by!(slug:)
    end

    def label
      I18n.t("contests.presets.#{key}.label", default: key.humanize)
    end

    private

    def validate!
      validate_totals!
      validate_nominations!
      validate_donation_unlocks!
    end

    def validate_totals!
      weights = criteria.sum { |row| row['weight'].to_i }
      raise Error, "#{key}: criteria weights must sum to 100 (got #{weights})" unless weights == 100

      split_total = prize_split.values.sum
      raise Error, "#{key}: prize_split must sum to 100 (got #{split_total})" unless split_total == 100
    end

    def validate_nominations!
      unknown = nominations - KNOWN_NOMINATIONS
      raise Error, "#{key}: unknown nominations #{unknown.join(', ')}" if unknown.any?
    end

    def validate_donation_unlocks!
      donation_goals.each do |goal|
        unlocks = Array(goal['unlocks']).map(&:to_s)
        bad = unlocks - KNOWN_NOMINATIONS
        raise Error, "#{key}: unknown donation unlock #{bad.join(', ')}" if bad.any?
      end
    end

    def parse_duration(value)
      match = value.to_s.match(/\A(\d+)([dw])\z/)
      raise Error, "#{key}: bad duration #{value.inspect}" unless match

      amount = match[1].to_i
      match[2] == 'w' ? amount.weeks : amount.days
    end
  end
end
