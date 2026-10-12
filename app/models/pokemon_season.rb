# frozen_string_literal: true

# A stretch of the Pokémon ladder (two calendar months). While open, titles and the top count trainers who fought in
# it; when it closes, standings land in season_results and ratings soft-reset toward 1500.
class PokemonSeason < ApplicationRecord
  has_many :season_results, dependent: :delete_all
  has_many :pokemon_battles, dependent: :nullify

  scope :open_seasons, -> { where(closed_at: nil) }
  scope :closed_seasons, -> { where.not(closed_at: nil) }

  validates :number, :starts_on, :ends_on, presence: true
  validates :number, uniqueness: true

  def self.current
    open_seasons.order(starts_on: :desc).first
  end

  # The open season, opening the next two-month block when none exists (first boot or after a close).
  def self.ensure_open!(at: Time.current)
    current || Pokemons::Seasons::Open.next!(at:)
  end

  def open?
    closed_at.nil?
  end

  def closed?
    !open?
  end
end
