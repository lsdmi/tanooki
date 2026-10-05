# frozen_string_literal: true

module Pokemons
  module Engine
    # One step of a battle, in order. Types and data:
    # - round_started: attacker, defender (combatant ids); version 2 adds first_striker
    # - trait_triggered: combatant, trait (version 2 emits them just before the hit or heal they change)
    # - round_resolved: attacker_score, defender_score (version 1)
    # - hit: striker, target (combatant ids), damage, hp_left, crit, dodged (damage 0), effect ('super' or 'weak' by
    #   the type chart, nil when neutral or dodged) (version 2)
    # - fainted: combatant, side (in version 2 it follows the knockout hit, at hp_left 0)
    # - healed: combatant, amount, hp_left (version 2, a friendly round winner)
    # - tired: combatant (the round winner), tiredness (its new value) (version 1)
    # - battle_won: side
    Event = Data.define(:type, :round, :data) do
      def initialize(type:, round:, data: {})
        super(type:, round:, data: data.freeze)
      end
    end
  end
end
