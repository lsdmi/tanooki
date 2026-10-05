# frozen_string_literal: true

module Pokemons
  module Engine
    # One Pokémon as it enters a battle. +character+ is the English trait key, +types+ the type chart keys in species
    # order. +base_hp+ / +base_attack+ are the species stats version 2 fights with; snapshots stored before version 2
    # have none and carry +power_level+, the retired 1–5 value version 1 fought with, instead.
    Combatant = Data.define(:id, :character, :power_level, :battle_experience, :types, :base_hp, :base_attack) do
      def initialize(id:, character:, battle_experience:, types:, power_level: nil, base_hp: nil, base_attack: nil)
        super(id:, character: character&.to_s, power_level:, battle_experience:, types: types.map(&:to_s).freeze,
              base_hp:, base_attack:)
      end
    end
  end
end
