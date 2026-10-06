# frozen_string_literal: true

module Reading
  # Undo for MarkReadThrough: deletes only the reads that call added and puts back the cursor position it
  # replaced (`resume_percent` is set only when it did).
  # Unread must not bump the library row's updated_at (it orders the library).
  class UndoReadThrough
    def initialize(user:, fiction:, chapter_ids:, resume_percent: nil)
      @user = user
      @fiction = fiction
      @chapter_ids = chapter_ids
      @resume_percent = resume_percent
    end

    def call
      removed = ReadingChapterRead.where(user: @user, fiction: @fiction, chapter_id: @chapter_ids).delete_all
      return false unless removed.positive?

      sync_progress
      ProgressCacheInvalidation.new(@user, @fiction).clear
      true
    end

    private

    def sync_progress
      progress = ReadingProgress.find_by(user: @user, fiction: @fiction)
      return unless progress

      progress.resume_percent = @resume_percent if @resume_percent
      progress.completed_count = ReadingChapterRead.read_keys(user: @user, fiction: @fiction).size
      progress.save!(touch: false)
    end
  end
end
