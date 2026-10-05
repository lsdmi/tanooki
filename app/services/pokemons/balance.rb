# frozen_string_literal: true

module Pokemons
  # Game timings in one place.
  module Balance
    CATCH_COOLDOWN = 4.hours
    TRAINING_COOLDOWN = 4.hours
    # Experience from a training that does not level up.
    TRAINING_EXPERIENCE = 1
    EXPERIENCE_CAP = 100
    # Also the opponent reroll window: one reroll per battle cooldown.
    BATTLE_COOLDOWN = 4.hours
    # Minimum gap between wild pop-ups. Longer than the catch cooldown so ignored pop-ups stay rare.
    ENCOUNTER_DELAY = 8.hours
  end
end
