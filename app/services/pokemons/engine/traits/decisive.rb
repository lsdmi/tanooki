# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Adds 0.1 to its type multiplier when it already beats the opponent's. Version 1 runs round traits before the
      # type multipliers are set (both are 1.0), so this never fires; kept for parity.
      class Decisive < Base
        KEY = 'decisive'
        ROUND_PRIORITY = 5

        def before_round(own, opponent)
          [own.with(type: own.type + 0.1), opponent] if own.type > opponent.type
        end
      end
    end
  end
end
