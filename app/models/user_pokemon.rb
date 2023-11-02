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

  BATTLE_TRAINING_SUCCESS = 'Вітаємо, із набуттям нового бойового досвіду!'
  EVOLUTION_TRAINING_SUCCESS = 'Вітаємо, із набуттям нового якісного рівня!'
end
