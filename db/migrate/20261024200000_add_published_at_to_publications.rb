# frozen_string_literal: true

# Public time for a blog. A sketch published later keeps created_at as the draft day.
class AddPublishedAtToPublications < ActiveRecord::Migration[8.1]
  def up
    add_column :publications, :published_at, :datetime, precision: 6, after: :status
    backfill_published_at
    stamp_deferred_acquisition_tales
  end

  def down
    remove_column :publications, :published_at
  end

  private

  def backfill_published_at
    execute <<~SQL.squish
      UPDATE publications
      SET published_at = created_at
      WHERE status = 'published' AND published_at IS NULL
    SQL
  end

  # Acquisition sketches were inserted together on 2026-10-19, then published on later days.
  def stamp_deferred_acquisition_tales
    execute <<~SQL.squish
      UPDATE publications
      SET published_at = updated_at
      WHERE status = 'published'
        AND created_at >= '2026-10-19 18:58:00'
        AND created_at < '2026-10-19 18:59:00'
        AND updated_at >= DATE_ADD(created_at, INTERVAL 12 HOUR)
    SQL
  end
end
