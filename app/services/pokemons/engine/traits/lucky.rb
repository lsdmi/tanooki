# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Rolls luck from a higher range.
      class Lucky < Base
        KEY = 'lucky'

        def luck_range
          1.0..1.2
        end
      end
    end
  end
end
