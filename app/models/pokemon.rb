# frozen_string_literal: true

class Pokemon < ApplicationRecord
  extend FriendlyId

  friendly_id :slug_candidates

  belongs_to :ancestor, class_name: 'Pokemon', inverse_of: :descendants, optional: true
  has_many :descendants, foreign_key: :ancestor_id, class_name: 'Pokemon'

  has_many :user_pokemons, dependent: :destroy
  has_many :users, through: :user_pokemons

  has_one_attached :sprite

  validates :name, presence: true, uniqueness: true
  validates :power_level, :rarity,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :ancestor_id, :sprite, presence: true
  validates :descendant_level,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99 }

  RARITY_LEVELS = {
    common: 1,
    uncommon: 2,
    rare: 3,
    very_rare: 4,
    super_rare: 5
  }.freeze

  POWER_LEVELS = {
    weak: 1, # 0 - 200
    moderate: 2, # 201 - 300
    formidable: 3, # 301 - 400
    mighty: 4, # 401 - 500
    legendary: 5 # 501 - 600
  }.freeze

  enum rarities: RARITY_LEVELS
  enum power_levels: POWER_LEVELS

  before_destroy :nullify_descendant_references

  def slug_candidates
    [
      name.downcase
    ]
  end

  private

  def nullify_descendant_references
    descendants.update_all(ancestor_id: nil)
  end
end
