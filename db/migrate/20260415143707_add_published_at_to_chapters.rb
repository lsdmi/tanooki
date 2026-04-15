class AddPublishedAtToChapters < ActiveRecord::Migration[8.0]
  def change
    add_column :chapters, :published_at, :datetime, null: true, after: :views
    add_index :chapters, :published_at
  end
end
