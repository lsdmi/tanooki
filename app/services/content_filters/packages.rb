# frozen_string_literal: true

module ContentFilters
  # The only genre cuts a reader can turn on. One key at a time until the catalogue is larger.
  module Packages
    MAX = 1
    PLAIN_ROMANCE = 'romance_bl'
    SIMPLE_SLUGS = {
      'shelves' => %w[bl gl lgbt],
      'another_world' => %w[fantasy isekai],
      'heavens' => %w[xianxia wuxia xuanhuan],
      'lights_on' => %w[horror thriller]
    }.freeze
    GROUPS = {
      relationships: %w[romance_bl shelves],
      worlds: %w[another_world heavens],
      moods: %w[lights_on]
    }.freeze

    def self.keys
      GROUPS.values.flatten
    end

    def self.key?(key)
      keys.include?(key.to_s)
    end

    def self.genre_ids_for(package_keys)
      slugs = Array(package_keys).flat_map { |key| SIMPLE_SLUGS[key.to_s] }.uniq
      return [] if slugs.empty?

      Genre.where(slug: slugs).pluck(:id)
    end

    def self.romance_id
      id_for('romance')
    end

    def self.premise_ids
      Genre.where(slug: SIMPLE_SLUGS.fetch('shelves')).order(:slug).pluck(:id)
    end

    def self.id_for(slug)
      Genre.find_by(slug:)&.id
    end
  end
end
