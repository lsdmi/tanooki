# frozen_string_literal: true

module Pokemons
  # Wild encounter roll: throttled catch chance and rarity-weighted random species, recorded as a PokemonEncounter.
  # Guests keep only the encounter id and their guest token in the session; see AuthCatch.guest_encounter.
  class WildCatch
    ENCOUNTER_CHANCE = 0.02

    attr_reader :session, :user

    def initialize(session:, user:)
      @user = user
      @session = session
    end

    def call
      precatch_session

      rate = catch_rate
      return nil if rate.zero?
      return nil if rand > rate

      postcatch_session
      encounter
    end

    private

    def catch_rate
      return 0 if user && shown_recently?

      last_seen = user&.pokemon_last_catch || session[:pokemon_catch_last_seen]
      last_seen < Balance::ENCOUNTER_DELAY.ago ? ENCOUNTER_CHANCE : 0
    end

    # Signed-in users are throttled by their last catch, so an ignored pop-up would otherwise reappear on every page.
    def shown_recently?
      shown_at = session[:pokemon_catch_last_seen]
      shown_at.present? && Time.zone.parse(shown_at.to_s) > Balance::ENCOUNTER_DELAY.ago
    end

    def encounter
      pokemon = find_pokemon(WildCatchPool.sample_id)
      return nil if pokemon.nil?

      user ? PokemonEncounter.roll!(pokemon:, user:) : guest_encounter(pokemon)
    end

    def guest_encounter(pokemon)
      session[:pokemon_guest_token] ||= SecureRandom.base58(24)
      PokemonEncounter.roll!(pokemon:, guest_token: session[:pokemon_guest_token]).tap do |encounter|
        session[:pokemon_encounter_id] = encounter.id
      end
    end

    def find_pokemon(id)
      Pokemon.includes(sprite_attachment: :blob).find_by(id: id)
    end

    def precatch_session
      session[:pokemon_catch_last_seen] ||= Time.zone.now if user.nil?
      session[:pokemon_guest_caught] = nil
    end

    def postcatch_session
      session[:pokemon_catch_last_seen] = Time.zone.now
    end
  end
end
