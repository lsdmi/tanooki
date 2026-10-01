# frozen_string_literal: true

module Pokemons
  # Signed-in catch: claims the encounter behind the pop-up token and traps its species, once per catch cooldown.
  class Catch
    def initialize(user, token)
      @user = user
      @token = token.to_s
    end

    # Returns the caught encounter, or nil (on cooldown, or a stale, foreign, or already caught token).
    def call
      CooldownClaim.call(@user, :catch) do
        encounter = @user.pokemon_encounters.for_catch_token(@token)
        next unless encounter&.claim!

        CollectionUpdater.new(pokemon_id: encounter.pokemon_id, user_id: @user.id).trap
        encounter
      end
    end
  end
end
