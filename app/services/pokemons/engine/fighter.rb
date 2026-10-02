# frozen_string_literal: true

module Pokemons
  module Engine
    # A combatant's state inside one battle. Round traits work on a copy, so their changes last one round; only
    # +tiredness+ and +active+ carry over.
    Fighter = Data.define(:id, :character, :types, :power, :luck, :experience, :raw_total, :type, :tiredness,
                          :active) do
      def self.strength(power, luck, experience = 0)
        (power + experience) * luck
      end

      def score
        raw_total * type / tiredness
      end

      def trait
        Traits.for(character)
      end
    end
  end
end
