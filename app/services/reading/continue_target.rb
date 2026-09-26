# frozen_string_literal: true

module Reading
  # Where «Читати далі» (library) and «Продовжити» (fiction page) send the reader:
  # - resume chapter not read yet: that chapter, restoring the in-chapter position (resume=1);
  # - read and finished (position at or past FINISHED_PERCENT, or none, as on pre-rebuild rows): the following
  #   chapter from the top, or the same chapter when nothing follows;
  # - read but stopped mid-chapter, i.e. a later re-read: back into it with the restore.
  # The latest listable chapter read, or the fiction marked finished, is «Все прочитано».
  # A visit that completes the chapter reports 100% from then on (and so does a manual mark on the cursor
  # chapter), so a position captured one screen above the end still counts as finished.
  class ContinueTarget
    FINISHED_PERCENT = 90

    # listable: one row per chapter, latest first. read_keys: from Reading::ReadKeys.
    def initialize(progress:, viewer:, listable:, read_keys:)
      @progress = progress
      @viewer = viewer
      @listable = listable
      @read_keys = read_keys
    end

    def all_read?
      return true if @progress.finished?

      latest = @listable.first
      latest.present? && read?(latest)
    end

    # Nil only when nothing is listable.
    def chapter
      return @chapter if defined?(@chapter)

      @chapter = resolve_chapter
    end

    # True when the target is the resume chapter itself, so the reader can restore the in-chapter position.
    def resume?
      chapter.present? && chapter.id == @progress.chapter_id
    end

    def read?(chapter)
      @read_keys.include?(ReadingChapterRead.chapter_key(chapter))
    end

    private

    def resolve_chapter
      resume = @progress.chapter
      return @listable.last unless resume
      return resume unless read?(resume) && finished_position?

      Library::ChapterNavigation.following_chapter(@progress.fiction, resume, viewer: @viewer) || resume
    end

    def finished_position?
      percent = @progress.resume_percent
      percent.nil? || percent >= FINISHED_PERCENT
    end
  end
end
