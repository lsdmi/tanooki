# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Neither side's experience counts this round. It runs first so the other round traits build on it.
      class Friendly < Base
        KEY = 'friendly'
        ROUND_PRIORITY = 1

        def before_round(own, opponent)
          [own, opponent].map do |fighter|
            fighter.with(experience: 1, raw_total: Fighter.strength(fighter.power, fighter.luck))
          end
        end
      end
    end
  end
end
