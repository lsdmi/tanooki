# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Losing still wears the winner out a little more.
      class Agile < Base
        KEY = 'agile'

        def after_defeat
          0.1
        end
      end
    end
  end
end
