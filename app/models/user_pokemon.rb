# frozen_string_literal: true

class UserPokemon < ApplicationRecord
  belongs_to :user
  belongs_to :pokemon

  enum character: {
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

  def pokemon_name
    pokemon.name
  end

  def pokemon_power_level
    pokemon.power_level
  end
end
