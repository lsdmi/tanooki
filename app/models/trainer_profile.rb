# frozen_string_literal: true

# A user's Pokémon game state: dex rating, cooldown clocks, and the pinned battle opponent.
class TrainerProfile < ApplicationRecord
  belongs_to :user

  def training_on_cooldown?
    last_training_at&.after?(Pokemons::Balance::TRAINING_COOLDOWN.ago) || false
  end

  # Counts battles on either side: being attacked rests the team too.
  def battle_on_cooldown?
    last_battle_at&.after?(Pokemons::Balance::BATTLE_COOLDOWN.ago) || false
  end
end
