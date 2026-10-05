# frozen_string_literal: true

# Elemental type for Pokemon. +key+ (fire, water, …) keys the type chart and colours; the label is in uk.yml.
class PokemonType < ApplicationRecord
  # The labels live in pokemons.types; dropped in a later deploy.
  self.ignored_columns += %w[name]

  has_many :pokemon_type_relations, dependent: :destroy
  has_many :pokemons, through: :pokemon_type_relations

  def self.label(key) = I18n.t(key, scope: 'pokemons.types')

  def label = self.class.label(key)
end
