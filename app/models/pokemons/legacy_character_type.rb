# frozen_string_literal: true

module Pokemons
  # Reads a Ukrainian trait label as its key: the code running before KeyUserPokemonCharacters can still write labels
  # while the deploy rolls out. Removed once a later deploy rewrites those rows.
  class LegacyCharacterType < ActiveModel::Type::String
    KEYS = {
      'Меткий' => 'agile', 'Амбітний' => 'ambitious', 'Сміливий' => 'brave', 'Самовпевнений' => 'confident',
      'Рішучий' => 'decisive', 'Дружелюбний' => 'friendly', 'Терплячий' => 'hardy', 'Незалежний' => 'independent',
      'Таланистий' => 'lucky', 'Впертий' => 'patient', 'Наполегливий' => 'persistent', 'Гордівливий' => 'prideful'
    }.freeze

    def deserialize(value)
      KEYS.fetch(value, value)
    end
  end
end
