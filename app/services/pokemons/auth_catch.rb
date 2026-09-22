# frozen_string_literal: true

module Pokemons
  # Single entry point for Devise login/signup/OmniAuth Pokemon side effects.
  # Controllers call this instead of CollectionUpdater / SignupCatchAssigner directly.
  class AuthCatch
    def self.guest_catch_pending?(session)
      session[:pokemon_guest_caught].present? && session[:caught_pokemon_id].present?
    end

    def self.transfer_guest_catch!(user:, session:)
      CollectionUpdater.new(pokemon_id: session[:caught_pokemon_id], user_id: user.id).trap
    end

    def self.assign_on_signup!(user:, session:)
      SignupCatchAssigner.new(user, session).perform
    end

    def self.after_omniauth!(user:, session:)
      return :without_pokemon if user.nil?

      if guest_catch_pending?(session)
        transfer_guest_catch!(user: user, session: session)
        :with_pokemon
      else
        CollectionUpdater.new(pokemon_id: nil, user_id: user.id).grant if user.pokemons.empty?
        :without_pokemon
      end
    end
  end
end
