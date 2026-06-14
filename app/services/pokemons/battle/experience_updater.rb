# frozen_string_literal: true

module Pokemons
  module Battle
    # Updates Pokemon battle experience after a combat round.
    class ExperienceUpdater
      include Constants

      def initialize(attacker, defender, attacker_experience, defender_experience)
        @attacker = attacker
        @defender = defender
        @attacker_experience = attacker_experience
        @defender_experience = defender_experience
      end

      def update
        attacker_got_experience = calculate_experience_gain(@attacker_experience, @defender_experience)
        defender_got_experience = calculate_experience_gain(@defender_experience, @attacker_experience)

        @attacker.update(battle_experience: exp_gain(@attacker.character, @attacker_experience,
                                                     attacker_got_experience))
        @defender.update(battle_experience: exp_gain(@defender.character, @defender_experience,
                                                     defender_got_experience))

        apply_persistent_character_effects
      end

      private

      def calculate_experience_gain(attacker_experience, defender_experience)
        if (attacker_experience - EXPERIENCE_THRESHOLDS[:high_gain]) < defender_experience
          EXPERIENCE_GAINS[:high]
        elsif (attacker_experience - EXPERIENCE_THRESHOLDS[:low_gain]) < defender_experience
          EXPERIENCE_GAINS[:low]
        else
          EXPERIENCE_GAINS[:none]
        end
      end

      def exp_gain(character, experience, got_experience)
        if got_experience.nonzero? && experience < EXPERIENCE_THRESHOLDS[:confident_max] && character == 'confident'
          got_experience *= 2
          experience += got_experience
        elsif got_experience.nonzero? && experience < EXPERIENCE_THRESHOLDS[:regular_max]
          experience += got_experience
        end

        experience
      end

      def apply_persistent_character_effects
        if @attacker.character == 'persistent'
          CharacterTraits.handle_persistent_character(@attacker, @attacker_experience)
        end
        return unless @defender.character == 'persistent'

        CharacterTraits.handle_persistent_character(@defender, @defender_experience)
      end
    end
  end
end
