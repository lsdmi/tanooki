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
    # A pair that fought this recently (either side attacking) plays unranked.
    RANKED_REMATCH_GAP = 24.hours
    # Opponents are trainers who attacked, caught or trained this recently. Being attacked does not count: a trainer
    # who left would otherwise stay "active" from the battles they are offered for.
    ACTIVE_WINDOW = 30.days
    # The opponent is drawn from this many active trainers with the nearest Glicko-2 ratings.
    NEAREST_OPPONENTS = 5
    # Recent defenders the attacker is not offered again while anyone else is available.
    RECENT_OPPONENTS = 3
  end
end
