# frozen_string_literal: true

# Three quests per trainer per calendar day (Europe/Kiev); progress bumps from Catch / BattleStart / Training / reading.
class CreateTrainerDailyQuests < ActiveRecord::Migration[8.1]
  def change
    create_table :trainer_daily_quests, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.date :quest_on, null: false
      t.string :quest_key, null: false, limit: 64
      t.integer :progress, null: false, default: 0
      t.integer :target, null: false
      t.datetime :completed_at
      t.timestamps

      t.index %i[user_id quest_on quest_key], unique: true, name: 'index_trainer_daily_quests_on_user_day_key'
    end
  end
end
