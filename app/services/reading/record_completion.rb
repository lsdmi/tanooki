# frozen_string_literal: true

module Reading
  # Adds one chapter to the user's sparse read set. Never fills gaps and never moves the resume cursor.
  class RecordCompletion
    attr_reader :chapter, :user, :source

    def initialize(chapter:, user:, source:)
      @chapter = chapter
      @user = user
      @source = source
    end

    def call
      return false unless user
      return false unless insert_read

      sync_completed_count
      ProgressCacheInvalidation.new(user, fiction).clear
      true
    end

    private

    def fiction
      chapter.fiction
    end

    def insert_read
      return false if ReadingChapterRead.exists?(user:, chapter:)

      ReadingChapterRead.create!(user:, chapter:, fiction:, completed_at: Time.current, source:)
      true
    rescue ActiveRecord::RecordNotUnique
      false
    end

    # Distinct chapters, not rows: reading two translations of one chapter counts once.
    def sync_completed_count
      find_or_start_progress.update!(completed_count: ReadingChapterRead.read_keys(user:, fiction:).size)
    end

    # No library row yet (the engaged request failed or is still in flight): this chapter becomes the resume point.
    def find_or_start_progress
      ReadingProgress.find_or_create_by!(user:, fiction:) do |progress|
        progress.chapter = chapter
        progress.resume_at = Time.current
      end
    rescue ActiveRecord::RecordNotUnique
      ReadingProgress.find_by!(user:, fiction:)
    end
  end
end
