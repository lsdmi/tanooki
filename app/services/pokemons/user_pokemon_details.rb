# frozen_string_literal: true

module Pokemons
  # Resolves one of the user's own party slots (+UserPokemon+) and the evolution it follows next (+PokemonEvolution+)
  # for the details UI. Someone else's id raises RecordNotFound (404): the panel has a training button.
  class UserPokemonDetails
    def initialize(user, pokemon_id)
      @user = user
      @pokemon_id = pokemon_id
    end

    def call
      Outcomes::OperationOutcome.new(
        success: true,
        data: {
          selected_pokemon: selected_pokemon,
          evolution: selected_pokemon.next_evolution
        }
      )
    end

    private

    attr_reader :user, :pokemon_id

    def selected_pokemon
      @selected_pokemon ||= user.user_pokemons.includes(pokemon: { sprite_attachment: :blob }).find(pokemon_id)
    end
  end
end
