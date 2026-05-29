# frozen_string_literal: true

module Library
  # View helpers delegating to {ChapterNavigation}.
  module ChapterNavigationHelper
    delegate :chapter_index, :unique_chapters, to: ChapterNavigation

    def previous_chapter(fiction, chapter, viewer: nil)
      ChapterNavigation.previous_chapter(fiction, chapter, viewer: viewer)
    end

    def following_chapter(fiction, chapter, viewer: nil)
      ChapterNavigation.following_chapter(fiction, chapter, viewer: viewer)
    end
  end
end
