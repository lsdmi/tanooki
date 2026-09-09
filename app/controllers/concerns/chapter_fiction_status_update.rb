# frozen_string_literal: true

# Syncs listing chapter projections after chapter create/update.
module ChapterFictionStatusUpdate
  extend ActiveSupport::Concern

  private

  def refresh_chapter_stats
    Catalog::RefreshChapterStats.call(@chapter.fiction.reload)
  end
end
