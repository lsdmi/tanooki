# frozen_string_literal: true

module Reading
  # Moves the user's resume cursor to an engaged chapter, with the in-chapter locator when the reader sent one.
  # Never marks chapters read.
  class RecordProgress
    attr_reader :chapter, :user, :locator

    def initialize(chapter:, user:, locator: nil)
      @chapter = chapter
      @user = user
      @locator = locator
    end

    def call
      return false unless user

      progress = find_progress
      return RecordPosition.new(chapter:, user:, locator:).call if already_on_chapter?(progress)

      started = progress.new_record?
      return false unless save_resume!(progress)

      clear_caches(started:)
      true
    end

    private

    def find_progress
      ReadingProgress.find_or_initialize_by(fiction_id: chapter.fiction.id, user_id: user.id)
    end

    def already_on_chapter?(progress)
      progress.persisted? && progress.chapter_id == chapter.id
    end

    # Reads outlive a removed library row, so a fresh row starts from the existing read set.
    # The previous chapter's locator never carries over.
    def save_resume!(progress)
      progress.chapter_id = chapter.id
      progress.resume_at = Time.current
      progress.assign_attributes(locator&.attributes || ResumeLocator::CLEARED)
      if progress.new_record?
        progress.completed_count = ReadingChapterRead.read_keys(user:, fiction: chapter.fiction).size
      end
      progress.save
    end

    # A new row adds the fiction to the library; moving an existing cursor only changes «Читати далі».
    def clear_caches(started:)
      invalidation = ProgressCacheInvalidation.new(user, chapter.fiction)
      started ? invalidation.clear : invalidation.clear_resume
    end
  end
end
