class AddFiction < ActiveRecord::Migration[7.0]
  def change
    create_table :fictions do |t|
      t.string :slug, null: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.text :description, null: false
      t.integer :views, default: 0
      t.string :status, null: false
      t.string :author, null: false
      t.string :translator
      t.integer :total_chapters, default: 0

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :fictions, :slug, unique: true

    create_table :chapters do |t|
      t.string :slug, null: false
      t.references :fiction, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.integer :number, null: false
      t.integer :views, default: 0

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :chapters, :slug, unique: true
  end
end
