# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # A species as the report needs it: labels for the tables and the stats both engine versions fight with.
    Species = Data.define(:id, :dex_id, :name, :rarity, :types, :base_hp, :base_attack) do
      def self.catalogue
        Pokemon.includes(:pokemon_types).order(:id).map do |pokemon|
          new(id: pokemon.id, dex_id: pokemon.dex_id, name: pokemon.name, rarity: pokemon.read_attribute(:rarity),
              types: pokemon.types.map(&:name), base_hp: pokemon.base_hp, base_attack: pokemon.base_attack)
        end
      end

      # The official strength the report ranks species by.
      def strength
        Math.sqrt(base_hp * base_attack)
      end

      # The card's might tier (StatTiers); version 1 fights with it in place of the retired power level.
      def might
        StatTiers.for(self).might
      end

      def combatant(id, experience, character = nil)
        Engine::Combatant.new(id:, character:, power_level: might, battle_experience: experience, types:, base_hp:,
                              base_attack:)
      end
    end
  end
end
