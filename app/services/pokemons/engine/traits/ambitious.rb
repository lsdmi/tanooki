# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Pins the opponent's luck to the bottom of its range (1.0 for a lucky opponent, 0.9 otherwise).
      class Ambitious < Base
        KEY = 'ambitious'
        ROUND_PRIORITY = 2

        def before_round(own, opponent)
          luck = opponent.character == Lucky::KEY ? 1.0 : 0.9
          [own, opponent.with(luck:, raw_total: Fighter.strength(opponent.power, luck, opponent.experience))]
        end
      end
    end
  end
end
