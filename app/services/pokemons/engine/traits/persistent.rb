# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # One extra experience point every round while below the cap, win or lose.
      class Persistent < Base
        KEY = 'persistent'
        CAP = 115

        def experience_after(experience, gain, cap)
          super + (experience < CAP ? 1 : 0)
        end
      end
    end
  end
end
