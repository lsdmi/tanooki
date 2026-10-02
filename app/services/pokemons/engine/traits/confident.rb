# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Gains double experience, up to a higher cap.
      class Confident < Base
        KEY = 'confident'
        CAP = 115

        def experience_after(experience, gain, cap)
          return experience + (gain * 2) if gain.nonzero? && experience < CAP

          super
        end
      end
    end
  end
end
