# frozen_string_literal: true

module Reading
  # Derives read / current / unread status for chapters in the reader drawer.
  class ChapterDrawerProgress
    include Library::ChapterNavigation

    def self.build(fiction:, viewer:, current_chapter: nil)
      new(fiction:, viewer:, current_chapter:).tap(&:prepare)
    end

    def initialize(fiction:, viewer:, current_chapter: nil)
      @fiction = fiction
      @viewer = viewer
      @current_chapter_id = current_chapter&.id
      @unique_chapters = []
      @progress_index = nil
      @finished = false
    end

    def prepare
      @unique_chapters = unique_chapters(Library::ChapterCatalog.ordered_chapters(@fiction, viewer: @viewer))
      progress = @viewer && ReadingProgress.find_by(fiction_id: @fiction.id, user_id: @viewer.id)

      if progress&.finished?
        @finished = true
      elsif progress&.chapter
        @progress_index = chapter_index(@unique_chapters, progress.chapter)
      end

      self
    end

    def status_for(chapter)
      return :current if chapter.id == @current_chapter_id
      return :read if @finished
      return :unread unless @progress_index

      status_from_progress_index(chapter)
    end

    def status_from_progress_index(chapter)
      index = chapter_index(@unique_chapters, chapter)
      if index < @progress_index
        :read
      elsif index == @progress_index
        :current
      else
        :unread
      end
    end
  end
end
