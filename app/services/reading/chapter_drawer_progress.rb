# frozen_string_literal: true

module Reading
  # Derives chapter row status for the reader drawer and the fiction page list from `ReadKeys`:
  # :current (open in the reader), :read, :in_progress (the resume chapter, not read yet) or :unread.
  # Never infers reads from the resume chapter. Reading one translation ticks all translations of that chapter.
  class ChapterDrawerProgress
    def self.build(fiction:, viewer:, current_chapter: nil)
      new(fiction:, viewer:, current_chapter:).tap(&:prepare)
    end

    def initialize(fiction:, viewer:, current_chapter: nil)
      @fiction = fiction
      @viewer = viewer
      @current_chapter_id = current_chapter&.id
      @resume_chapter_id = nil
      @read_keys = Set.new
      @finished = false
    end

    def prepare
      return self unless @viewer

      progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: @viewer.id)
      @finished = progress&.finished? || false
      @resume_chapter_id = progress&.chapter_id
      @read_keys = ReadKeys.call(user: @viewer, fiction: @fiction, progress:) unless @finished
      self
    end

    def status_for(chapter)
      return :current if chapter.id == @current_chapter_id
      return :read if read?(chapter)
      return :in_progress if chapter.id == @resume_chapter_id

      :unread
    end

    def read?(chapter)
      read_key?(ReadingChapterRead.chapter_key(chapter))
    end

    def read_key?(key)
      @finished || @read_keys.include?(key)
    end

    # Translations of one chapter share a key, so `keys` counts chapters, not rows.
    def read_count(keys)
      keys.count { |key| read_key?(key) }
    end

    # Counts are shown once something is read; a shelf alone puts the progress on the first chapter.
    def started?
      @finished || @read_keys.any?
    end

    # A finished fiction shows every chapter read regardless of the read set, so a toggle would do nothing visible.
    def toggleable?
      @viewer.present? && !@finished
    end
  end
end
