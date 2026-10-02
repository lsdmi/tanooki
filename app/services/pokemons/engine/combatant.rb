# frozen_string_literal: true

module Pokemons
  module Engine
    # One Pokémon as it enters a battle. +character+ is the English trait key, +power_level+ the stored 1–5 value,
    # +types+ the type chart keys in species order.
    Combatant = Data.define(:id, :character, :power_level, :battle_experience, :types) do
      def initialize(id:, character:, power_level:, battle_experience:, types:)
        super(id:, character: character&.to_s, power_level:, battle_experience:, types: types.map(&:to_s).freeze)
      end
    end
  end
end
