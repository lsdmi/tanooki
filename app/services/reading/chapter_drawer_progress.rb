# frozen_string_literal: true

module Reading
  # Derives read / current / unread status for chapters in the reader drawer from `ReadKeys`.
  # Never infers reads from the resume chapter. Reading one translation ticks all translations of that chapter.
  class ChapterDrawerProgress
    def self.build(fiction:, viewer:, current_chapter: nil)
      new(fiction:, viewer:, current_chapter:).tap(&:prepare)
    end

    def initialize(fiction:, viewer:, current_chapter: nil)
      @fiction = fiction
      @viewer = viewer
      @current_chapter_id = current_chapter&.id
      @read_keys = Set.new
      @finished = false
    end

    def prepare
      return self unless @viewer

      progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: @viewer.id)
      @finished = progress&.finished? || false
      @read_keys = ReadKeys.call(user: @viewer, fiction: @fiction, progress:) unless @finished
      self
    end

    def status_for(chapter)
      return :current if chapter.id == @current_chapter_id
      return :read if read?(chapter)

      :unread
    end

    def read?(chapter)
      @finished || @read_keys.include?(ReadingChapterRead.chapter_key(chapter))
    end

    # A finished fiction shows every chapter read regardless of the read set, so a toggle would do nothing visible.
    def toggleable?
      @viewer.present? && !@finished
    end
  end
end
