# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Battle experience counts double in its strength.
      class Brave < Base
        KEY = 'brave'

        def experience_multiplier
          2
        end
      end
    end
  end
end
