# frozen_string_literal: true

module Pokemons
  module Engine
    # One step of a battle, in order. Types and data:
    # - round_started: attacker, defender (combatant ids)
    # - trait_triggered: combatant, trait
    # - round_resolved: attacker_score, defender_score
    # - fainted: combatant, side
    # - battle_won: side
    Event = Data.define(:type, :round, :data) do
      def initialize(type:, round:, data: {})
        super(type:, round:, data: data.freeze)
      end
    end
  end
end
