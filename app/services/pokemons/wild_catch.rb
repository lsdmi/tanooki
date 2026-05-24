# frozen_string_literal: true

module Pokemons
  # Session-backed wild encounter: throttled catch chance and rarity-weighted random species.
  class WildCatch
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
      caught_pokemon
    end

    private

    def catch_rate
      last_seen = user&.pokemon_last_catch || session[:pokemon_catch_last_seen]

      if last_seen < 365.days.ago then 1
      elsif last_seen < 8.hours.ago then 0.02
      else
        0
      end
    end

    def caught_pokemon
      pokemon_id = caught_pokemon_id
      session[:caught_pokemon_id] = pokemon_id if user.nil?
      find_caught_pokemon(pokemon_id)
    end

    def caught_pokemon_id
      WildCatchPool.sample_id
    end

    def find_caught_pokemon(id)
      Pokemon.includes(sprite_attachment: :blob).find_by(id: id)
    end

    def precatch_session
      session[:pokemon_catch_last_seen] ||= Time.zone.now
      session[:pokemon_guest_caught] = nil
    end

    def postcatch_session
      session[:pokemon_catch_last_seen] = Time.zone.now
    end
  end
end
