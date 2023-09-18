class CreatePokemonBattleLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :pokemon_battle_logs do |t|
      t.references :attacker, foreign_key: { to_table: :users }, null: false
      t.references :defender, foreign_key: { to_table: :users }, null: false
      t.references :winner, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end

    change_table :users do |t|
      t.integer :battle_win_rate, default: 50, after: :avatar_id
    end
  end
end
