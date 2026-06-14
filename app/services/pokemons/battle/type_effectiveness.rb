# frozen_string_literal: true

module Pokemons
  module Battle
    # Applies Pokemon type matchup multipliers to battle stats.
    class TypeEffectiveness
      def self.calculate(stats, own_pokemon, opponent_pokemon)
        effectiveness = 1.0

        own_pokemon.types.each do |attacker_type|
          opponent_pokemon.types.each do |defender_type|
            effectiveness *= TypeAdvantage.effectiveness(attacker_type.name, defender_type.name)
          end
        end

        stats[:type] = effectiveness
      end
    end
  end
end
