# frozen_string_literal: true

module Pokemons
  # Single entry point for Devise login/signup/OmniAuth Pokemon side effects.
  # Controllers call this instead of CollectionUpdater / SignupCatchAssigner directly.
  class AuthCatch
    GUEST_SESSION_KEYS = %i[pokemon_encounter_id pokemon_guest_caught].freeze

    def self.guest_encounter(session)
      return if session[:pokemon_encounter_id].blank? || session[:pokemon_guest_token].blank?

      PokemonEncounter.claimable.find_by(
        id: session[:pokemon_encounter_id], user_id: nil, guest_token: session[:pokemon_guest_token]
      )
    end

    # Returns the claimed encounter, or nil so the caller can fall back (starter on signup, nothing on login).
    def self.transfer_guest_catch!(user:, session:)
      encounter = guest_encounter(session) if session[:pokemon_guest_caught].present?
      return unless encounter&.claim!

      GUEST_SESSION_KEYS.each { |key| session.delete(key) }
      CollectionUpdater.new(pokemon_id: encounter.pokemon_id, user_id: user.id).trap
      encounter
    end

    def self.assign_on_signup!(user:, session:)
      SignupCatchAssigner.new(user, session).perform
    end

    def self.after_omniauth!(user:, session:)
      return :without_pokemon if user.nil?
      return :with_pokemon if transfer_guest_catch!(user:, session:)

      CollectionUpdater.new(pokemon_id: nil, user_id: user.id).grant if user.pokemons.empty?
      :without_pokemon
    end
  end
end
