# frozen_string_literal: true

# chapter_count is the number of chapters a reader can open. Rows still on a timer no longer count.
class RecountPublicChapterSlots < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE fictions
      LEFT JOIN (
        SELECT fiction_id, COUNT(*) AS slots
        FROM (
          SELECT fiction_id, number, volume_number
          FROM chapters
          WHERE deleted_at IS NULL
            AND status = 'published'
            AND (published_at IS NULL OR published_at <= UTC_TIMESTAMP())
          GROUP BY fiction_id, number, volume_number
        ) released_slots
        GROUP BY fiction_id
      ) counts ON counts.fiction_id = fictions.id
      SET fictions.chapter_count = COALESCE(counts.slots, 0)
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE fictions
      LEFT JOIN (
        SELECT fiction_id, COUNT(*) AS slots
        FROM (
          SELECT fiction_id, number, volume_number
          FROM chapters
          WHERE deleted_at IS NULL
            AND status = 'published'
          GROUP BY fiction_id, number, volume_number
        ) published_slots
        GROUP BY fiction_id
      ) counts ON counts.fiction_id = fictions.id
      SET fictions.chapter_count = COALESCE(counts.slots, 0)
    SQL
  end
end
