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

  FAILURE_MESSSAGE = 'У-упс, невдала спроба!'
  SUCCESS_MESSSAGE = 'Вітаємо, із оновленням у команді!'
end
