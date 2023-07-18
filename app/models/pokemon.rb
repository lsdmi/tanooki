# frozen_string_literal: true

class Pokemon < ApplicationRecord
  extend FriendlyId

  friendly_id :slug_candidates

  has_many :user_pokemons, dependent: :destroy
  has_many :users, through: :user_pokemons

  has_one_attached :sprite

  validates :name, presence: true, uniqueness: true
  validates :power_level, :rarity,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :sprite, presence: true

  RARITY_LEVELS = {
    common: 1,
    uncommon: 2,
    rare: 3,
    very_rare: 4,
    super_rare: 5
  }.freeze

  POWER_LEVELS = {
    weak: 1,
    moderate: 2,
    formidable: 3,
    mighty: 4,
    legendary: 5
  }.freeze

  enum rarities: RARITY_LEVELS
  enum power_levels: POWER_LEVELS

  def slug_candidates
    [
      name.downcase
    ]
  end
end
