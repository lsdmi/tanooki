# frozen_string_literal: true

module Pokemons
  module Battle
    # Maps post-battle experience gap to a tiredness penalty value.
    class Tiredness
      def self.calculate(attacker, defender)
        difference = attacker - defender

        if difference >= Constants::TIREDNESS_THRESHOLDS[:overwhelming_victory]
          Constants::TIREDNESS_VALUES[:overwhelming_victory]
        elsif difference >= Constants::TIREDNESS_THRESHOLDS[:significant_victory]
          Constants::TIREDNESS_VALUES[:significant_victory]
        else
          Constants::TIREDNESS_VALUES[:close_victory]
        end
      end
    end
  end
end
