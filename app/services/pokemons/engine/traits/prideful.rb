# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Cuts the opponent's power by a sixth (divides by 1.2).
      class Prideful < Base
        KEY = 'prideful'
        ROUND_PRIORITY = 3

        def before_round(own, opponent)
          power = opponent.power / 1.2
          [own, opponent.with(power:, raw_total: Fighter.strength(power, opponent.luck, opponent.experience))]
        end
      end
    end
  end
end
