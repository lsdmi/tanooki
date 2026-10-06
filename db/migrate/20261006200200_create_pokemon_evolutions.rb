# frozen_string_literal: true

# Evolutions get their own rows, so a species can branch (Eevee). characters limits a branch to Pokémon with one of
# those traits; NULL means any. Backfilled from pokemons.descendant_id / descendant_level, dropped in a later deploy.
class CreatePokemonEvolutions < ActiveRecord::Migration[8.1]
  def change
    create_table :pokemon_evolutions, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :from, null: false, foreign_key: { to_table: :pokemons }, index: false
      t.references :to, null: false, foreign_key: { to_table: :pokemons }
      t.integer :min_level, null: false
      t.json :characters
      t.timestamps
      t.index %i[from_id to_id], unique: true
    end

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          INSERT INTO pokemon_evolutions (from_id, to_id, min_level, created_at, updated_at)
          SELECT id, descendant_id, descendant_level, UTC_TIMESTAMP(6), UTC_TIMESTAMP(6)
          FROM pokemons WHERE descendant_id <> id
        SQL
      end
    end
  end
end
