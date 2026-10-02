# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Pulls the opponent's type multiplier down to its own. Version 1 runs round traits before the type multipliers
      # are set (both are 1.0), so this never fires; kept for parity.
      class Patient < Base
        KEY = 'patient'
        ROUND_PRIORITY = 4

        def before_round(own, opponent)
          [own, opponent.with(type: own.type)] if own.type < opponent.type
        end
      end
    end
  end
end
