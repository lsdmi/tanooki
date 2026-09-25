# frozen_string_literal: true

# chapter_id stays the resume chapter; resume_at marks the last engaged read, completed_count caches the read set size.
# legacy_read_through_chapter_id snapshots the pre-rebuild pointer so existing readers keep «N / total» and drawer
# ticks. Rows created after this migration never get one; the read set itself is not backfilled.
class AddResumeAtAndCompletedCountToReadingProgresses < ActiveRecord::Migration[8.1]
  def change
    change_table :reading_progresses, bulk: true do |t|
      t.datetime :resume_at, null: true, after: :status
      t.integer :completed_count, null: false, default: 0, after: :resume_at
      t.references :legacy_read_through_chapter, null: true, after: :completed_count,
                                                 foreign_key: { to_table: :chapters, on_delete: :nullify }
    end

    up_only do
      execute 'UPDATE reading_progresses SET legacy_read_through_chapter_id = chapter_id'
    end
  end
end
