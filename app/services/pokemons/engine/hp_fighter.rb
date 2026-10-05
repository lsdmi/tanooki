# frozen_string_literal: true

module Pokemons
  module Engine
    # A combatant inside a version 2 battle. +hp+ and +survived+ (persistent's lethal hit is spent) carry over between
    # rounds; +wounded+ (took a hit this round) and +countered+ (patient answered it) reset every round.
    HpFighter = Data.define(:id, :character, :types, :max_hp, :hp, :attack, :wounded, :countered, :survived) do
      def power
        max_hp * attack
      end
    end
  end
end
