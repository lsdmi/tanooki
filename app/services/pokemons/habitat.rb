# frozen_string_literal: true

module Pokemons
  # Resolves boosted wild types from a fiction's genres, a genre hub, or publication tags via
  # +config/pokemon_habitats.yml+.
  class Habitat
    CONFIG_PATH = Rails.root.join('config/pokemon_habitats.yml')
    TYPE_CHART_PATH = Rails.root.join('config/type_advantage.yml')
    DEFAULT_BOOST = 4

    def self.for(genre: nil, fiction: nil, publication: nil)
      new(genre_slugs: genre_slugs_for(genre, fiction), tag_names: tag_names_for(publication))
    end

    def self.config
      @config ||= load_yaml(CONFIG_PATH)
    end

    def self.reload!
      @config = load_yaml(CONFIG_PATH)
      @known_type_keys = nil
    end

    def self.boost
      config.fetch('boost', DEFAULT_BOOST).to_i.clamp(1, 20)
    end

    def self.known_type_keys
      @known_type_keys ||= load_yaml(TYPE_CHART_PATH).keys.map(&:to_s)
    end

    def self.load_yaml(path)
      YAML.safe_load_file(path).to_h
    end
    private_class_method :load_yaml

    def self.genre_slugs_for(genre, fiction)
      slugs = []
      slugs << genre.slug if genre.respond_to?(:slug) && genre.slug.present?
      slugs.concat(Array(fiction&.genres).filter_map { |row| row.slug if row.respond_to?(:slug) })
      slugs
    end
    private_class_method :genre_slugs_for

    def self.tag_names_for(publication)
      Array(publication&.tags).filter_map { |tag| tag.name if tag.respond_to?(:name) }
    end
    private_class_method :tag_names_for

    def initialize(genre_slugs: [], tag_names: [], type_keys: [])
      @genre_slugs = normalize_keys(genre_slugs)
      @tag_names = normalize_keys(tag_names)
      @explicit_type_keys = normalize_keys(type_keys)
    end

    def type_keys
      keys = explicit_type_keys.dup
      keys.concat(genre_slugs.flat_map { |slug| types_for('genres', slug) })
      keys.concat(tag_names.flat_map { |name| types_for('tags', name) })
      keys.uniq & self.class.known_type_keys
    end

    def present?
      type_keys.any?
    end

    private

    attr_reader :genre_slugs, :tag_names, :explicit_type_keys

    def normalize_keys(values)
      Array(values).filter_map { |value| value.to_s.downcase.presence }.uniq
    end

    def types_for(section, key)
      Array(self.class.config.dig(section, key)).map(&:to_s)
    end
  end
end
