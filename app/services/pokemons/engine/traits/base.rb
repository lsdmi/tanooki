# frozen_string_literal: true

module Pokemons
  module Engine
    module Traits
      # Hooks every trait can override. The simulator calls them for both sides.
      class Base
        KEY = nil
        # Round hooks run in this order (attacker first on a tie); nil means the trait has no round hook.
        ROUND_PRIORITY = nil

        def key
          self.class::KEY
        end

        def round_priority
          self.class::ROUND_PRIORITY
        end

        # Roster: rolled once when the team is built.
        def luck_range
          0.9..1.1
        end

        def power_multiplier
          100
        end

        def experience_multiplier
          1
        end

        # Round: returns [own, opponent] Fighters for this round, or nil when the trait does not apply.
        def before_round(_own, _opponent)
          nil
        end

        # Tiredness change for the round winner when this Pokémon won, or lost; nil when none.
        def after_victory
          nil
        end

        def after_defeat
          nil
        end

        def experience_after(experience, gain, cap)
          gain.nonzero? && experience < cap ? experience + gain : experience
        end
      end
    end
  end
end
