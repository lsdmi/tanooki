# frozen_string_literal: true

module Pokemons
  module Battle
    # Applies character trait effects during Pokemon battle rounds.
    class CharacterEffectApplier
      def initialize(attacker, defender, attacker_stats, defender_stats)
        @attacker = attacker
        @defender = defender
        @attacker_stats = attacker_stats
        @defender_stats = defender_stats
      end

      def apply
        apply_friendly_character_effects
        apply_ambitious_character_effects
        apply_prideful_character_effects
        apply_patient_character_effects
        apply_decisive_character_effects
      end

      private

      def apply_friendly_character_effects
        return unless [@attacker.character, @defender.character].include?('friendly')

        CharacterTraits.handle_friendly_character(@attacker_stats, @defender_stats)
      end

      def apply_ambitious_character_effects
        CharacterTraits.handle_ambitious_character(@defender_stats, @defender) if @attacker.character == 'ambitious'
        return unless @defender.character == 'ambitious'

        CharacterTraits.handle_ambitious_character(@attacker_stats, @attacker)
      end

      def apply_prideful_character_effects
        CharacterTraits.handle_prideful_character(@defender_stats) if @attacker.character == 'prideful'
        CharacterTraits.handle_prideful_character(@attacker_stats) if @defender.character == 'prideful'
      end

      def apply_patient_character_effects
        CharacterTraits.handle_patient_character(@attacker_stats, @defender_stats) if @attacker.character == 'patient'
        return unless @defender.character == 'patient'

        CharacterTraits.handle_patient_character(@defender_stats, @attacker_stats)
      end

      def apply_decisive_character_effects
        CharacterTraits.handle_decisive_character(@attacker_stats, @defender_stats) if @attacker.character == 'decisive'
        return unless @defender.character == 'decisive'

        CharacterTraits.handle_decisive_character(@defender_stats, @attacker_stats)
      end
    end
  end
end
