# frozen_string_literal: true

# One row per EPUB build with its size and worker memory. Kept apart from epub_export_requests, which are destroyed
# a day after they expire.
class CreateEpubExportStats < ActiveRecord::Migration[8.1]
  def change
    create_table :epub_export_stats do |t|
      t.bigint :epub_export_request_id, :source_bytes, null: false
      t.bigint :user_id, :epub_bytes
      t.integer :chapters, :rss_before_mb, :rss_peak_mb, :rss_after_mb, null: false
      t.float :seconds, null: false
      t.datetime :created_at, null: false
    end
  end
end
