# frozen_string_literal: true

# A user's Pokémon game state: Glicko-2 rating, cooldown clocks, and the pinned battle opponent.
class TrainerProfile < ApplicationRecord
  # The 0–100 rating, replaced by glicko_*; dropped in the next deploy.
  self.ignored_columns += %w[rating]

  belongs_to :user

  def training_on_cooldown?
    last_training_at&.after?(Pokemons::Balance::TRAINING_COOLDOWN.ago) || false
  end

  # Counts battles on either side: being attacked rests the team too.
  def battle_on_cooldown?
    last_battle_at&.after?(Pokemons::Balance::BATTLE_COOLDOWN.ago) || false
  end

  # The stored rating; the time since the last battle is applied when the next one is rated.
  def glicko
    Pokemons::Ratings::Glicko2::Rating.new(rating: glicko_rating, deviation: glicko_deviation,
                                           volatility: glicko_volatility)
  end

  def glicko=(value)
    self.glicko_rating, self.glicko_deviation, self.glicko_volatility = value.deconstruct
  end

  # Rating periods since the last battle at +time+, fractional; 0 before the first.
  def idle_periods(time)
    last_battle_at ? (time - last_battle_at) / Pokemons::Ratings::Glicko2::PERIOD : 0
  end
end
