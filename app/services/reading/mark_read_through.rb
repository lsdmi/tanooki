# frozen_string_literal: true

module Reading
  # «Позначити прочитаними 1–85»: reads every listed chapter from the first up to the target (list order) that is
  # not read yet, in one transaction with `source: manual`. Returns what it added so `UndoReadThrough` removes
  # only that. Like RecordCompletion it starts a library row when there is none, with the target as the resume
  # point, and marks the cursor chapter's stored position finished when the range covers it.
  class MarkReadThrough
    Result = Data.define(:chapter_ids, :resume_percent)

    def initialize(chapter:, user:)
      @chapter = chapter
      @user = user
    end

    def call
      progress = ReadingProgress.find_by(user: @user, fiction:)
      unread = unread_through(progress)
      return Result.new(chapter_ids: [], resume_percent: nil) if unread.empty?

      insert_reads(unread)
      previous_percent = sync_progress(progress || start_progress, unread)
      ProgressCacheInvalidation.new(@user, fiction).clear
      Result.new(chapter_ids: unread.map(&:id), resume_percent: previous_percent)
    end

    private

    def fiction = @chapter.fiction

    def unread_through(progress)
      read_keys = ReadKeys.call(user: @user, fiction:, progress:)
      chapters_through.reject { |chapter| read_keys.include?(ReadingChapterRead.chapter_key(chapter)) }
    end

    def chapters_through
      listed = Library::ChapterNavigation.unique_chapters(
        Library::ChapterCatalog.listed_chapters(fiction, viewer: @user, order: :asc)
      )
      key = ReadingChapterRead.chapter_key(@chapter)
      last = listed.index { |chapter| ReadingChapterRead.chapter_key(chapter) == key }
      last ? listed.first(last + 1) : []
    end

    # One row per chapter key: a read of any translation ticks the chapter.
    def insert_reads(chapters)
      now = Time.current
      ReadingChapterRead.transaction do
        chapters.each do |chapter|
          ReadingChapterRead.create!(user: @user, fiction:, chapter:, completed_at: now, source: 'manual')
        end
      end
    end

    # Returns the cursor's position before the change when it moved, for the undo.
    def sync_progress(progress, chapters)
      previous = progress.resume_percent
      cursor_key = progress.chapter && ReadingChapterRead.chapter_key(progress.chapter)
      covers_cursor = previous && chapters.any? { |chapter| ReadingChapterRead.chapter_key(chapter) == cursor_key }
      progress.resume_percent = 100 if covers_cursor
      progress.completed_count = ReadingChapterRead.read_keys(user: @user, fiction:).size
      progress.save!
      previous if covers_cursor
    end

    def start_progress
      ReadingProgress.find_or_create_by!(user: @user, fiction:) do |progress|
        progress.chapter = @chapter
        progress.resume_at = Time.current
      end
    rescue ActiveRecord::RecordNotUnique
      ReadingProgress.find_by!(user: @user, fiction:)
    end
  end
end
