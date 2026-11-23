# frozen_string_literal: true

# Free-form fiction tags (themes, tropes, settings) — separate from genres and from publication `tags`.
class CreateFictionTags < ActiveRecord::Migration[8.1]
  def change
    create_table :fiction_tags, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.string :name, null: false, limit: 40
      t.string :slug, null: false
      t.string :status, null: false, default: 'active', limit: 16
      t.boolean :explicit, null: false, default: false
      t.integer :fictions_count, null: false, default: 0
      t.timestamps

      t.index :name, unique: true
      t.index :slug, unique: true
    end

    create_table :fiction_tag_links, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :fiction, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :fiction_tag, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps

      t.index %i[fiction_id fiction_tag_id], unique: true
    end
  end
end
