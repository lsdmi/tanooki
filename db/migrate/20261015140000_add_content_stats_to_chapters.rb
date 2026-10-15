# frozen_string_literal: true

# Denormalized chapter body stats so lists, contests and size gates never load action_text_rich_texts.
# Filled on save when the rich text is already loaded; existing rows are filled by Chapters::ContentStatsBackfillJob.
class AddContentStatsToChapters < ActiveRecord::Migration[8.1]
  def change
    change_table :chapters, bulk: true do |t|
      t.integer :word_count, null: false, default: 0, after: :views
      t.integer :body_bytes, null: false, default: 0, after: :word_count
      t.string :excerpt, limit: 300, after: :body_bytes
    end
  end
end
