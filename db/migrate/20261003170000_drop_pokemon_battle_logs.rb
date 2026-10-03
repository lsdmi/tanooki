# frozen_string_literal: true

# Every row was converted into pokemon_battles (20261003160000) and the Action Text bodies were purged.
class DropPokemonBattleLogs < ActiveRecord::Migration[8.1]
  def change
    drop_table :pokemon_battle_logs, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :attacker, :defender, :winner, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
