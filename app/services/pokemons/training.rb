# frozen_string_literal: true

module Pokemons
  # Trains one of the user's Pokémon, once per training cooldown.
  class Training
    def initialize(user, user_pokemon_id)
      @user = user
      @user_pokemon_id = user_pokemon_id
    end

    # Returns the notice text, or nil while on cooldown.
    def call
      CooldownClaim.call(@user, :training) { @user.user_pokemons.find(@user_pokemon_id).train![:alert] }
    end
  end
end
