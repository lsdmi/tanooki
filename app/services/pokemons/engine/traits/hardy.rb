# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Tires less from a win.
      class Hardy < Base
        KEY = 'hardy'

        def after_victory
          -0.1
        end
      end
    end
  end
end
