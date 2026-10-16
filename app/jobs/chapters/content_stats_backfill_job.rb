# frozen_string_literal: true

module Chapters
  # One-shot backfill of chapters.word_count / body_bytes / excerpt. Enqueue with
  # `Chapters::ContentStatsBackfillJob.perform_later` (or again with an after_id to resume).
  class ContentStatsBackfillJob < ApplicationJob
    BATCH = 500

    queue_as :heavy

    def perform(after_id = 0)
      batch = next_batch(after_id)
      return if batch.empty?

      write_stats(batch)
      self.class.perform_later(batch.last.id) if batch.size == BATCH
    end

    private

    def next_batch(after_id)
      Chapter.unscoped.order(:id).where(Chapter.arel_table[:id].gt(after_id)).limit(BATCH).to_a
    end

    def write_stats(batch)
      ids = batch.map(&:id)
      # Default scope hides soft-deleted bodies, and chapter.content would then build a new row
      # that collides with the unique index. Read the stored body and save only the stat columns.
      bodies = ActionText::RichText.with_deleted.where(
        record_type: 'Chapter', name: 'content', record_id: ids
      ).index_by(&:record_id)

      Chapter.unscoped.where(id: ids).find_each do |chapter|
        chapter.assign_attributes(ContentStats.attributes_from(bodies[chapter.id]))
        chapter.save!(validate: false)
      end
    end
  end
end
