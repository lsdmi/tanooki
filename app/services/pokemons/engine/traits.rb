# frozen_string_literal: true

module Pokemons
  module Engine
    # One strategy object per UserPokemon character key; unknown or missing characters get the plain Base rules.
    module Traits
      def self.for(character)
        registry.fetch(character.to_s, BASE)
      end

      def self.registry
        @registry ||= [Agile, Ambitious, Brave, Confident, Decisive, Friendly, Hardy, Independent, Lucky, Patient,
                       Persistent, Prideful].to_h { |trait| [trait::KEY, trait.new] }.freeze
      end

      BASE = Base.new
    end
  end
end
