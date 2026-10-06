# frozen_string_literal: true

# Evolution lines become explicit: pokemons.line_root_id (was the ancestor_id convention) and pokemons.wild (was
# "rarity below 5"; only first forms appear in the wild). user_pokemons copies its species' line so one index keeps a
# user to one Pokémon per line. The old columns and the rarity of evolved forms change in a later deploy, once no
# running code reads rarity 5 as "not wild".
class AddLinesToPokemons < ActiveRecord::Migration[8.1]
  def up
    change_table :pokemons, bulk: true do |t|
      t.bigint :line_root_id, after: :id
      t.boolean :wild, null: false, default: false, after: :rarity
    end
    execute 'UPDATE pokemons SET line_root_id = ancestor_id, wild = (ancestor_id = id)'
    change_column_null :pokemons, :line_root_id, false
    add_index :pokemons, :line_root_id

    add_column :user_pokemons, :line_root_id, :bigint, after: :pokemon_id
    execute <<~SQL.squish
      UPDATE user_pokemons JOIN pokemons ON pokemons.id = user_pokemons.pokemon_id
      SET user_pokemons.line_root_id = pokemons.line_root_id
    SQL
    add_index :user_pokemons, %i[user_id line_root_id], unique: true
  end

  def down
    remove_index :user_pokemons, %i[user_id line_root_id]
    remove_column :user_pokemons, :line_root_id
    remove_index :pokemons, :line_root_id
    remove_columns :pokemons, :line_root_id, :wild
  end
end
