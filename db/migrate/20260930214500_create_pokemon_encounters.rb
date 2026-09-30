# frozen_string_literal: true

# Server-side wild encounters: the catch endpoint will claim a row instead of trusting a pokemon_id from the form.
# No CHECK for "user_id or guest_token": MySQL rejects CHECKs on columns used by an ON DELETE CASCADE foreign key.
class CreatePokemonEncounters < ActiveRecord::Migration[8.1]
  def change
    create_table :pokemon_encounters, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :user, null: true, index: false, foreign_key: { on_delete: :cascade }
      t.string :guest_token, limit: 32
      t.references :pokemon, null: false, foreign_key: { on_delete: :cascade }
      t.string :source, limit: 16, null: false, default: 'browse'
      t.boolean :shiny, null: false, default: false
      t.string :status, limit: 16, null: false, default: 'open'
      t.datetime :expires_at, null: false

      t.timestamps

      t.index %i[user_id status]
      t.index :guest_token
    end
  end
end
