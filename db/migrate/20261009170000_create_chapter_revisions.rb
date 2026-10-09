# frozen_string_literal: true

# Snapshots of a chapter body before an API edit. Pruned to the last 20 per chapter and 90 days.
class CreateChapterRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :chapter_revisions do |t|
      t.references :chapter, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false, size: :long
      t.references :user, null: false, foreign_key: true
      t.references :api_token, foreign_key: { on_delete: :nullify }
      t.timestamps
    end

    add_index :chapter_revisions, %i[chapter_id created_at]
  end
end
