# frozen_string_literal: true

# Listing progress columns on fictions: chapter_count, expected_chapters, timestamps.
# Rename lands before last_chapter_at so AFTER can target expected_chapters.
class AddListingProgressColumnsToFictions < ActiveRecord::Migration[8.0]
  def up
    add_chapter_count_and_rename_expected
    null_out_zero_expected_chapters
    add_listing_progress_timestamps
  end

  def down
    remove_listing_progress_timestamps
    restore_zero_expected_chapters
    restore_total_chapters
  end

  private

  def add_chapter_count_and_rename_expected
    change_table :fictions, bulk: true do |t|
      t.integer :chapter_count, null: false, default: 0, after: :adult_content
      t.rename :total_chapters, :expected_chapters
    end
  end

  def null_out_zero_expected_chapters
    change_column_default :fictions, :expected_chapters, from: 0, to: nil
    execute 'UPDATE fictions SET expected_chapters = NULL WHERE expected_chapters = 0'
  end

  def add_listing_progress_timestamps
    change_table :fictions, bulk: true do |t|
      t.datetime :last_chapter_at, after: :expected_chapters
      t.datetime :completed_at, after: :updated_at
      t.datetime :abandoned_at, after: :completed_at
      t.index %i[completed_at abandoned_at last_chapter_at],
              name: 'index_fictions_on_listing_progress'
    end
  end

  def remove_listing_progress_timestamps
    change_table :fictions, bulk: true do |t|
      t.remove_index name: 'index_fictions_on_listing_progress'
      t.remove :abandoned_at, :completed_at, :last_chapter_at
    end
  end

  def restore_zero_expected_chapters
    execute 'UPDATE fictions SET expected_chapters = 0 WHERE expected_chapters IS NULL'
    change_column_default :fictions, :expected_chapters, from: nil, to: 0
  end

  def restore_total_chapters
    change_table :fictions, bulk: true do |t|
      t.rename :expected_chapters, :total_chapters
      t.remove :chapter_count
    end
  end
end
