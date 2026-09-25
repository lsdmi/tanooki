# frozen_string_literal: true

module Reading
  # Stores where the reader is inside the resume chapter. Only the chapter the cursor is on takes a position,
  # so an unengaged chapter (or an older tab) never overwrites the locator. Library order stays put.
  class RecordPosition
    attr_reader :chapter, :user, :locator

    def initialize(chapter:, user:, locator:)
      @chapter = chapter
      @user = user
      @locator = locator
    end

    def call
      return false unless user && locator

      progress = find_resume_progress
      return false unless progress

      progress.assign_attributes(locator.attributes)
      return false unless progress.changed?

      progress.save!(touch: false)
      ProgressCacheInvalidation.new(user, chapter.fiction).clear_resume
      true
    end

    private

    def find_resume_progress
      ReadingProgress.find_by(user:, fiction_id: chapter.fiction_id, chapter_id: chapter.id)
    end
  end
end
