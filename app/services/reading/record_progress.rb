# frozen_string_literal: true

module Reading
  # Records the current chapter in the user's reading progress for a fiction.
  class RecordProgress
    attr_reader :chapter, :user

    def initialize(chapter:, user:)
      @chapter = chapter
      @user = user
    end

    def call
      return false unless user

      progress = find_progress
      return false if already_on_chapter?(progress)
      return false unless save_chapter!(progress)

      ProgressCacheInvalidation.new(user, chapter.fiction).clear
      true
    end

    private

    def find_progress
      ReadingProgress.find_or_initialize_by(fiction_id: chapter.fiction.id, user_id: user.id)
    end

    def already_on_chapter?(progress)
      progress.persisted? && progress.chapter_id == chapter.id
    end

    def save_chapter!(progress)
      progress.chapter_id = chapter.id
      progress.save
    end
  end
end
