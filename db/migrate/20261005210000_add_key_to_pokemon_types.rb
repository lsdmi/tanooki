# frozen_string_literal: true

# Types get stable English keys; the Ukrainian labels move to uk.yml (pokemons.types) and the name column is dropped
# in a later deploy. Stored battle teams switch to the keys too, so version 1 and 2 replays read the re-keyed chart.
class AddKeyToPokemonTypes < ActiveRecord::Migration[8.1]
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
    add_column :pokemon_types, :key, :string, limit: 16, after: :id
    KEYS.each { |name, key| execute "UPDATE pokemon_types SET `key` = #{quote(key)} WHERE name = #{quote(name)}" }
    unknown = select_values('SELECT name FROM pokemon_types WHERE `key` IS NULL')
    raise "Pokémon types without a key: #{unknown.join(', ')}" if unknown.any?

    change_column_null :pokemon_types, :key, false
    add_index :pokemon_types, :key, unique: true
    rekey_battle_teams(KEYS)
  end

  def down
    rekey_battle_teams(KEYS.invert)
    remove_column :pokemon_types, :key
  end

  private

  def rekey_battle_teams(mapping)
    Battle.where('JSON_LENGTH(attacker_team) > 0').find_each do |battle|
      teams = %w[attacker_team defender_team].index_with do |column|
        battle[column].map { |entry| entry.merge('types' => entry['types'].map { |type| mapping.fetch(type, type) }) }
      end
      battle.update_columns(teams)
    end
  end
end
