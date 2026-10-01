# frozen_string_literal: true

module Pokemons
  # Game timings in one place.
  module Balance
    CATCH_COOLDOWN = 4.hours
    TRAINING_COOLDOWN = 4.hours
    # Also the opponent reroll window: one reroll per battle cooldown.
    BATTLE_COOLDOWN = 4.hours
    # Minimum gap between wild pop-ups. Longer than the catch cooldown so ignored pop-ups stay rare.
    ENCOUNTER_DELAY = 8.hours
  end
end
