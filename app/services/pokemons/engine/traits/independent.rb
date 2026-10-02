# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # 20% more power.
      class Independent < Base
        KEY = 'independent'

        def power_multiplier
          120
        end
      end
    end
  end
end
