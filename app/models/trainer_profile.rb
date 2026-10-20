# frozen_string_literal: true

# A user's Pokémon game state: Glicko-2 rating, cooldown clocks, pinned opponent, and battle rosters.
class TrainerProfile < ApplicationRecord
  belongs_to :user

  attribute :item_effects, :json, default: -> { {} }

  validate :team_rosters_are_valid

  def item_effect(key)
    effects = item_effects
    effects.is_a?(Hash) ? effects[key.to_s] : nil
  end

  def write_item_effect!(key, value)
    effects = item_effects.is_a?(Hash) ? item_effects.dup : {}
    if value.nil?
      effects.delete(key.to_s)
    else
      effects[key.to_s] = value
    end
    update!(item_effects: effects)
  end

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

  private

  def team_rosters_are_valid
    %i[attack_team_ids defense_team_ids].each { |attribute| validate_team_roster(attribute) }
  end

  def validate_team_roster(attribute)
    ids = Array(self[attribute]).map(&:to_i)
    return if ids.empty? || add_team_shape_error(attribute, ids)

    errors.add(attribute, :invalid) if UserPokemon.where(user_id:, id: ids).count != ids.size
  end

  def add_team_shape_error(attribute, ids)
    if ids.size != ids.uniq.size
      errors.add(attribute, :taken)
    elsif ids.size > Pokemons::Balance::TEAM_SIZE
      errors.add(attribute, :too_long, count: Pokemons::Balance::TEAM_SIZE)
    end
  end
end
