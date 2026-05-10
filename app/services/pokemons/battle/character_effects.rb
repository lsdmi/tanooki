# frozen_string_literal: true

module Pokemons
  module Battle
    # Entry points for Pokémon battle personality hooks: mid-fight stat tweaks and post-victory traits.
    class CharacterEffects
      def self.apply(attacker, defender, attacker_stats, defender_stats)
        CharacterEffectApplier.new(attacker, defender, attacker_stats, defender_stats).apply
      end

      def self.apply_victory(winner, loser, attacker_side_team)
        if winner.character == 'hardy'
          Pokemons::Battle::CharacterTraits.handle_hardy_character(attacker_side_team.team, { id: winner.id })
        end
        return unless loser.character == 'agile'

        Pokemons::Battle::CharacterTraits.handle_agile_character(attacker_side_team.team, { id: winner.id })
      end
    end
  end
end
