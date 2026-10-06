# frozen_string_literal: true

# Pokemon owned by a user for the dex and battle features.
class UserPokemon < ApplicationRecord
  CHARACTERS = %w[agile ambitious brave confident decisive friendly hardy independent lucky patient persistent
                  prideful].freeze

  belongs_to :user
  belongs_to :pokemon

  # The labels rows written before KeyUserPokemonCharacters still hold; rewritten in a later deploy.
  attribute :character, Pokemons::LegacyCharacterType.new
  enum :character, CHARACTERS.index_with(&:itself)

  before_validation :copy_line_root

  # Gen 1 lines have at most two evolutions; the cap also stops an evolution cycle from looping forever.
  MAX_EVOLUTION_STEPS = 3

  delegate :name, to: :pokemon, prefix: true

  def self.character_label(character) = character && I18n.t(character, scope: 'pokemons.characters')

  def character_label = self.class.character_label(character)

  def train!
    return level_up_training! if rand(2).zero?

    cap = Pokemons::Balance::EXPERIENCE_CAP
    if battle_experience < cap
      update(battle_experience: [battle_experience + Pokemons::Balance::TRAINING_EXPERIENCE, cap].min)
    end
    { alert: I18n.t('pokemons.training.experience', name: pokemon_name) }
  end

  def level_up!
    update!(current_level: current_level + 1)
    evolve_if_ready!
  end

  # The evolution this Pokémon follows next (its trait picks a branch), or nil for a final form.
  def next_evolution = PokemonEvolution.next_for(pokemon_id, character)

  # The species this Pokémon should be at its level: several stages on if a threshold was lowered.
  def ready_species
    species = pokemon
    MAX_EVOLUTION_STEPS.times do
      evolution = species.evolution_for(character)
      break unless evolution && current_level >= evolution.min_level

      species = evolution.to
    end
    species
  end

  def evolve_if_ready!
    target = ready_species
    update!(pokemon: target) unless target == pokemon
  end

  private

  def copy_line_root
    self.line_root_id = pokemon&.line_root_id
  end

  def level_up_training!
    name = pokemon_name
    level_up!
    { alert: I18n.t('pokemons.training.level', name:) }
  end
end
