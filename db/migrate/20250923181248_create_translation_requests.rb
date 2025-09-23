class CreateTranslationRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :translation_requests do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.string :author
      t.string :source_url
      t.text :notes
      t.integer :votes_count, default: 0, null: false

      t.timestamps
    end

    add_index :translation_requests, :votes_count
    add_index :translation_requests, :created_at
  end
end
