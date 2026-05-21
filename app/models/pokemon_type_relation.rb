# frozen_string_literal: true

# Join model linking Pokemon to their types.
class PokemonTypeRelation < ApplicationRecord
  belongs_to :pokemon
  belongs_to :pokemon_type

  def type
    pokemon_type
  end
end
