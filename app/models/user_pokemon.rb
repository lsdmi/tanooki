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

  FAILURE_MESSSAGE = 'У-упс, невдала спроба!'
  SUCCESS_MESSSAGE = 'Вітаємо, із оновленням у команді!'
  TRAINING_FRAUD_ALERT = 'Ця дія наразі неможлива. Спробуйте пізніше.'

  delegate :name, :power_level, to: :pokemon, prefix: true

  def train!
    return level_up_training! if rand(2).zero?

    update(battle_experience: battle_experience + 1) if battle_experience < 100
    { alert: "#{pokemon_name} набув нового бойового досвіду!" }
  end

  private

  def level_up_training!
    Pokemons::CollectionUpdater.new(pokemon_id: pokemon.id, user_id: user.id).evolve
    { alert: "#{pokemon.name} набув нового якісного рівня!" }
  end
end
