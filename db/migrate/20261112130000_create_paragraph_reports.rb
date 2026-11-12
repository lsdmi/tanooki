# frozen_string_literal: true

# Reader reports of a translation error on one reader block (data-rp-i + quote + digest).
# Open-duplicate uniqueness is enforced in Chapters::CreateParagraphReport (MySQL has no
# partial unique indexes; a generated open_identity column fights existing FKs on ALTER).
class CreateParagraphReports < ActiveRecord::Migration[8.1]
  def change
    create_table :paragraph_reports do |t|
      t.bigint :user_id, null: false
      t.bigint :chapter_id, null: false
      t.integer :block_index, null: false
      t.string :quote, null: false, limit: 120
      t.string :digest, null: false, limit: 16
      t.string :message, limit: 500
      t.string :status, null: false, default: 'open', limit: 16
      t.bigint :resolved_by_id
      t.datetime :resolved_at
      t.timestamps

      t.index :user_id
      t.index %i[chapter_id status], name: 'index_paragraph_reports_on_chapter_and_status'
      t.index %i[user_id chapter_id], name: 'index_paragraph_reports_on_user_and_chapter'
      t.index %i[user_id chapter_id block_index digest status],
              name: 'index_paragraph_reports_on_open_lookup'
      t.index :resolved_by_id
    end

    add_foreign_key :paragraph_reports, :users, column: :user_id, on_delete: :cascade
    add_foreign_key :paragraph_reports, :chapters, column: :chapter_id, on_delete: :cascade
    add_foreign_key :paragraph_reports, :users, column: :resolved_by_id, on_delete: :nullify
  end
end
