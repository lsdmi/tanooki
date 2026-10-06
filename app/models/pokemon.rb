# frozen_string_literal: true

# Collectible creature used in the site dex and battle mini-game.
class Pokemon < ApplicationRecord
  extend FriendlyId

  # Replaced by line_root_id and pokemon_evolutions; dropped in a later deploy.
  self.ignored_columns += %w[ancestor_id descendant_id descendant_level]

  friendly_id :slug_candidates

  belongs_to :line_root, class_name: 'Pokemon', optional: true
  has_many :evolutions, class_name: 'PokemonEvolution', foreign_key: :from_id, inverse_of: :from, dependent: :destroy

  has_many :pokemon_type_relations, dependent: :destroy
  has_many :pokemon_types, through: :pokemon_type_relations

  has_many :user_pokemons, dependent: :destroy
  has_many :users, through: :user_pokemons

  has_one_attached :sprite

  validates :name, presence: true, uniqueness: true
  validates :rarity,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :dex_id, :sprite, presence: true
  validates :base_hp, :base_attack,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 255 }

  before_validation :fill_official_base_stats

  RARITY_LEVELS = {
    common: 1,
    uncommon: 2,
    rare: 3,
    very_rare: 4,
    super_rare: 5
  }.freeze

  STARTER_DEX_IDS = [1, 4, 7].freeze

  scope :wild, -> { where(wild: true) }

  def slug_candidates
    [
      name.downcase,
      [name.downcase, dex_id]
    ]
  end

  def should_generate_new_friendly_id?
    slug.blank? || (name_changed? && name.present?)
  end

  def rarity
    RARITY_LEVELS.key(read_attribute(:rarity))
  end

  def types
    pokemon_types
  end

  def evolution_for(character)
    evolutions.find { |evolution| evolution.for?(character) }
  end

  private

  # A new species only needs its dex number: blank stats take the official ones.
  def fill_official_base_stats
    official = Pokemons::BaseStats.for(dex_id) or return
    self.base_hp = official[:hp] if base_hp.blank?
    self.base_attack = official[:attack] if base_attack.blank?
  end
end
