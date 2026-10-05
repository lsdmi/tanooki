# frozen_string_literal: true

module Pokemons
  # Wild encounters in two steps, so a pop-up only counts once it is on screen. Turbo prefetches pages on hover, so
  # the page view (#roll) only rolls the 2% chance and writes nothing; a hit renders a frame whose request, made when
  # the page is actually shown, records the encounter and starts the gap (#call). The frame URL carries a signed
  # ticket, so that endpoint cannot be called to skip the roll.
  # Guests keep only the encounter id and their guest token in the session; see AuthCatch.guest_encounter.
  class WildCatch
    ENCOUNTER_CHANCE = 0.02
    TICKET_TTL = 10.minutes

    attr_reader :session, :user

    def self.verifier
      Rails.application.message_verifier('pokemons/wild_encounter')
    end

    def initialize(session:, user:)
      @user = user
      @session = session
    end

    # A ticket for the pop-up frame, or nil.
    def roll
      stamp_new_guest
      return unless eligible? && rand < ENCOUNTER_CHANCE

      self.class.verifier.generate(owner, expires_in: TICKET_TTL)
    end

    # The encounter, or nil when the ticket is not this visitor's or a pop-up was shown within the delay.
    def call(ticket)
      return unless ticket.is_a?(String) && self.class.verifier.verified(ticket) == owner
      return unless eligible? && !encountered_recently?

      encounter&.tap { session[:pokemon_catch_last_seen] = Time.zone.now }
    end

    private

    def owner
      user ? "user:#{user.id}" : 'guest'
    end

    # Every response rewrites the session cookie, so a request that overlaps this one (a hover prefetch) can drop the
    # session stamp; the rows themselves are the reliable record.
    def encountered_recently?
      recent = PokemonEncounter.where(created_at: Balance::ENCOUNTER_DELAY.ago..)
      return recent.exists?(user_id: user.id) if user

      session[:pokemon_guest_token].present? && recent.exists?(guest_token: session[:pokemon_guest_token])
    end

    # A guest's first page view is the one session write without a pop-up: new guests wait the delay too, and clients
    # that drop cookies (crawlers rendering the page) never become eligible.
    def stamp_new_guest
      session[:pokemon_catch_last_seen] ||= Time.zone.now if user.nil?
    end

    def eligible?
      return false if shown_recently?
      return session[:pokemon_catch_last_seen].present? if user.nil?

      !user.trainer_profile.last_catch_at&.after?(Balance::ENCOUNTER_DELAY.ago)
    end

    # Signed-in users are also throttled by their last catch, but an ignored pop-up would otherwise reappear at once.
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
      session.delete(:pokemon_guest_caught)
      PokemonEncounter.roll!(pokemon:, guest_token: session[:pokemon_guest_token]).tap do |encounter|
        session[:pokemon_encounter_id] = encounter.id
      end
    end

    def find_pokemon(id)
      Pokemon.includes(sprite_attachment: :blob).find_by(id: id)
    end
  end
end
