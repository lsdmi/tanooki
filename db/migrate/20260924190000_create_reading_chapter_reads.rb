# frozen_string_literal: true

# Sparse set of chapters a user actually finished. Never backfilled from reading_progresses.chapter_id.
class CreateReadingChapterReads < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_chapter_reads, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :fiction, null: false, foreign_key: { on_delete: :cascade }
      t.references :chapter, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :completed_at, null: false
      t.string :source, limit: 16, null: false

      t.timestamps

      t.index %i[user_id chapter_id], unique: true
      t.index %i[user_id fiction_id]
    end
  end
end
