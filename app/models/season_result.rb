# frozen_string_literal: true

# A trainer's final place in a closed Pokémon season, taken just before the soft rating reset.
class SeasonResult < ApplicationRecord
  belongs_to :pokemon_season
  belongs_to :user

  validates :place, :percentile, :glicko_rating, :glicko_deviation, :glicko_floor, presence: true
  validates :user_id, uniqueness: { scope: :pokemon_season_id }
end
