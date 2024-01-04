# frozen_string_literal: true

class Pokemon < ApplicationRecord
  extend FriendlyId

  attr_accessor :type_ids

  friendly_id :slug_candidates

  belongs_to :ancestor, class_name: 'Pokemon', inverse_of: :descendants, optional: true
  belongs_to :descendant, foreign_key: :descendant_id, class_name: 'Pokemon'
  has_many :descendants, foreign_key: :ancestor_id, class_name: 'Pokemon'

  has_many :pokemon_type_relations, dependent: :destroy
  has_many :pokemon_types, through: :pokemon_type_relations

  has_many :user_pokemons, dependent: :destroy
  has_many :users, through: :user_pokemons

  has_one_attached :sprite

  validates :name, presence: true, uniqueness: true
  validates :power_level, :rarity,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :ancestor_id, :dex_id, :sprite, presence: true
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

  STARTER_DEX_IDS = [1, 4, 7].freeze

  before_destroy :nullify_descendant_references

  def slug_candidates
    [
      name.downcase
    ]
  end

  def power_level
    POWER_LEVELS.key(read_attribute(:power_level))
  end

  def rarity
    RARITY_LEVELS.key(read_attribute(:rarity))
  end

  def types
    pokemon_types
  end

  private

  def nullify_descendant_references
    descendants.update_all(ancestor_id: nil)
  end
end
