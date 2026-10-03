# frozen_string_literal: true

# Battles as data instead of rendered HTML: (engine_version, seed, teams) replays a battle, and events re-render it.
# Replaces pokemon_battle_logs (Action Text) once 2.4 converts the old rows. Deleting a user deletes their battles.
class CreatePokemonBattles < ActiveRecord::Migration[8.1]
  TRAINER = { null: false, foreign_key: { to_table: :users, on_delete: :cascade } }.freeze

  def change
    create_table :pokemon_battles, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :attacker, :defender, index: false, **TRAINER
      t.references :winner, **TRAINER
      t.bigint :seed, null: false
      t.integer :engine_version, limit: 2, null: false
      t.json :attacker_team, :defender_team, :events, null: false
      t.integer :rating_delta_attacker, :rating_delta_defender, limit: 1, null: false
      t.datetime :created_at, null: false
      %i[attacker_id defender_id].each { |trainer_id| t.index [trainer_id, :created_at] }
    end
  end
end
