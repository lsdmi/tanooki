# frozen_string_literal: true

# Daily-quest rewards: candy balance + ledger, bag rows, and one-shot item effect flags on the profile.
class AddTrainerItemsAndCandies < ActiveRecord::Migration[8.1]
  def up
    add_column :trainer_profiles, :candies, :integer, null: false, default: 0, after: :last_studio_visit_at
    add_column :trainer_profiles, :item_effects, :json, after: :candies
    execute "UPDATE trainer_profiles SET item_effects = '{}'"
    change_column_null :trainer_profiles, :item_effects, false

    create_table :trainer_items, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :item_key, null: false, limit: 64
      t.integer :quantity, null: false, default: 0
      t.timestamps

      t.index %i[user_id item_key], unique: true, name: 'index_trainer_items_on_user_and_key'
    end

    create_table :candy_transactions, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :amount, null: false
      t.string :reason, null: false, limit: 64
      t.string :source_type, limit: 64
      t.bigint :source_id
      t.datetime :created_at, null: false

      t.index %i[user_id created_at]
      t.index %i[source_type source_id]
    end
  end

  def down
    drop_table :candy_transactions
    drop_table :trainer_items
    remove_column :trainer_profiles, :item_effects
    remove_column :trainer_profiles, :candies
  end
end
