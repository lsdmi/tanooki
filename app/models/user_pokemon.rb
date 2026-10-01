# frozen_string_literal: true

# Pokemon owned by a user for the dex and battle features.
class UserPokemon < ApplicationRecord
  belongs_to :user
  belongs_to :pokemon

  enum :character, {
    agile: 'Меткий',
    ambitious: 'Амбітний',
    brave: 'Сміливий',
    confident: 'Самовпевнений',
    decisive: 'Рішучий',
    friendly: 'Дружелюбний',
    hardy: 'Терплячий',
    independent: 'Незалежний',
    lucky: 'Таланистий',
    patient: 'Впертий',
    persistent: 'Наполегливий',
    prideful: 'Гордівливий'
  }

  DEFAULT_TEAM_SIZE = 6
  # Gen 1 lines have at most two evolutions; the cap also stops a descendant cycle from looping forever.
  MAX_EVOLUTION_STEPS = 3

  FAILURE_MESSSAGE = 'У-упс, невдала спроба!'
  SUCCESS_MESSSAGE = 'Вітаємо, із оновленням у команді!'
  TRAINING_FRAUD_ALERT = 'Ця дія наразі неможлива. Спробуйте пізніше.'

  delegate :name, :power_level, to: :pokemon, prefix: true

  def train!
    return level_up_training! if rand(2).zero?

    update(battle_experience: battle_experience + 1) if battle_experience < 100
    { alert: "#{pokemon_name} набув нового бойового досвіду!" }
  end

  def level_up!
    update!(current_level: current_level + 1)
    evolve_if_ready!
  end

  # The species this Pokémon should be at its level: several stages on if an admin lowered a threshold.
  def ready_species
    species = pokemon
    MAX_EVOLUTION_STEPS.times do
      break unless species.evolves_at?(current_level)

      species = species.descendant
    end
    species
  end

  def evolve_if_ready!
    target = ready_species
    update!(pokemon: target) unless target == pokemon
  end

  private

  def level_up_training!
    name = pokemon_name
    level_up!
    { alert: "#{name} набув нового якісного рівня!" }
  end
end
