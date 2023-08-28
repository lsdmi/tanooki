# frozen_string_literal: true

class PokemonType < ApplicationRecord
  has_many :pokemon_type_relations, dependent: :destroy
  has_many :pokemons, through: :pokemon_type_relations
end
