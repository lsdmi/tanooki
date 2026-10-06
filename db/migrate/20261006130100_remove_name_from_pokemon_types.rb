# frozen_string_literal: true

# The type labels live in uk.yml (pokemons.types). Battle teams the old code stored while the previous deploy rolled
# out still name their types in Ukrainian; they switch to keys before the names go.
class RemoveNameFromPokemonTypes < ActiveRecord::Migration[8.1]
  KEYS = {
    'Звичайний' => 'normal', 'Вогняний' => 'fire', 'Водяний' => 'water', 'Електричний' => 'electric',
    "Трав'яний" => 'grass', 'Льодовий' => 'ice', 'Бойовий' => 'fighting', 'Отруйний' => 'poison',
    'Ґрунтовий' => 'ground', 'Повітряний' => 'flying', 'Психічний' => 'psychic', 'Комашиний' => 'bug',
    'Скельний' => 'rock', 'Примарний' => 'ghost', 'Драконячий' => 'dragon'
  }.freeze

  class Battle < ActiveRecord::Base
    self.table_name = 'pokemon_battles'
  end

  def up
    Battle.where('JSON_LENGTH(attacker_team) > 0').find_each do |battle|
      teams = %w[attacker_team defender_team].index_with do |column|
        battle[column].map { |entry| entry.merge('types' => entry['types'].map { |type| KEYS.fetch(type, type) }) }
      end
      battle.update_columns(teams) if teams.any? { |column, team| team != battle[column] }
    end
    remove_column :pokemon_types, :name
  end

  def down
    add_column :pokemon_types, :name, :string, after: :key
    KEYS.each { |name, key| execute "UPDATE pokemon_types SET name = #{quote(name)} WHERE `key` = #{quote(key)}" }
    change_column_null :pokemon_types, :name, false
  end
end
