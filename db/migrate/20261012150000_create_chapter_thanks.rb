# frozen_string_literal: true

# One-tap reader thanks on a chapter, with the chapter's count kept as a counter cache.
class CreateChapterThanks < ActiveRecord::Migration[8.1]
  def change
    create_table :chapter_thanks do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :chapter, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
      t.index %i[user_id chapter_id], unique: true, name: 'index_chapter_thanks_on_user_and_chapter'
    end

    add_column :chapters, :thanks_count, :integer, default: 0, null: false, after: :comments_count
  end
end
