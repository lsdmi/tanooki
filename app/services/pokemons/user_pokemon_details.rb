# frozen_string_literal: true

module Pokemons
  # Resolves a party slot (+UserPokemon+) and its evolution (+Pokemon+ descendant) for the details UI.
  class UserPokemonDetails
    def initialize(pokemon_id)
      @pokemon_id = pokemon_id
    end

    def call
      Outcomes::OperationOutcome.new(
        success: true,
        data: {
          selected_pokemon: selected_pokemon,
          descendant: descendant
        }
      )
    end

    private

    attr_reader :pokemon_id

    def selected_pokemon
      @selected_pokemon ||= UserPokemon.includes(:pokemon).find(pokemon_id)
    end

    def descendant
      return nil unless selected_pokemon.pokemon.descendant != selected_pokemon.pokemon

      @descendant ||= selected_pokemon.pokemon.descendant
    end
  end
end
