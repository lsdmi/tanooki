# frozen_string_literal: true

# Listing progress columns on fictions: chapter_count, expected_chapters, timestamps.
# Sequential AFTER positions so chapter_count sits before the renamed expected_chapters.
class AddListingProgressColumnsToFictions < ActiveRecord::Migration[8.0]
  # rubocop:disable Rails/BulkChangeTable
  def up
    add_column :fictions, :chapter_count, :integer, null: false, default: 0, after: :adult_content
    rename_column :fictions, :total_chapters, :expected_chapters
    change_column_default :fictions, :expected_chapters, from: 0, to: nil
    execute 'UPDATE fictions SET expected_chapters = NULL WHERE expected_chapters = 0'
    add_column :fictions, :last_chapter_at, :datetime, after: :expected_chapters
    add_column :fictions, :completed_at, :datetime, after: :updated_at
    add_column :fictions, :abandoned_at, :datetime, after: :completed_at
    add_index :fictions, %i[completed_at abandoned_at last_chapter_at],
              name: 'index_fictions_on_listing_progress'
  end

  def down
    remove_index :fictions, name: 'index_fictions_on_listing_progress'
    remove_column :fictions, :abandoned_at
    remove_column :fictions, :completed_at
    remove_column :fictions, :last_chapter_at
    execute 'UPDATE fictions SET expected_chapters = 0 WHERE expected_chapters IS NULL'
    change_column_default :fictions, :expected_chapters, from: nil, to: 0
    rename_column :fictions, :expected_chapters, :total_chapters
    remove_column :fictions, :chapter_count
  end
  # rubocop:enable Rails/BulkChangeTable
end
