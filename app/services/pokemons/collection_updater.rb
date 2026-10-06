# frozen_string_literal: true

module Pokemons
  # Grants a starter or traps a caught species into a user's collection. Either way the Pokémon gains a level and
  # evolves if that reaches its next stage (UserPokemon#level_up!).
  class CollectionUpdater
    attr_reader :pokemon_id, :user_id

    def initialize(pokemon_id:, user_id:)
      @pokemon_id = pokemon_id
      @user_id = user_id
    end

    def grant
      UserPokemon.create!(user_id:, pokemon_id: starter.id, character: sample_character).level_up!
    end

    # A catch from a line the user already owns levels up the Pokémon they have, whatever stage it is at.
    def trap
      find_or_create_user_pokemon.level_up!
    end

    private

    def sample_character
      UserPokemon::CHARACTERS.sample
    end

    def starter
      Pokemon.find_by(dex_id: Pokemon::STARTER_DEX_IDS.sample) || Pokemon.first
    end

    def find_or_create_user_pokemon
      UserPokemon.joins(:pokemon).find_by(user_id:, pokemons: { line_root_id: pokemon_data.line_root_id }) ||
        UserPokemon.create!(user_id:, pokemon_id:, character: sample_character)
    end

    def pokemon_data
      return @pokemon_data if defined?(@pokemon_data)

      @pokemon_data = Pokemon.find_by(id: pokemon_id)
    end
  end
end
