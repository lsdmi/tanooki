# frozen_string_literal: true

module Chapters
  # Drops API snapshots older than 90 days, then anything past the newest 20 on a chapter.
  class PruneRevisionsJob < ApplicationJob
    KEEP = 20
    RETENTION = 90.days

    queue_as :default

    def perform
      ChapterRevision.where(created_at: ...RETENTION.ago).delete_all
      over_cap.each { |chapter_id| prune_chapter(chapter_id) }
    end

    private

    def over_cap
      ChapterRevision.group(:chapter_id).having('COUNT(*) > ?', KEEP).count.keys
    end

    def prune_chapter(chapter_id)
      ids = ChapterRevision.where(chapter_id:).order(created_at: :desc, id: :desc).offset(KEEP).ids
      ChapterRevision.where(id: ids).delete_all
    end
  end
end
