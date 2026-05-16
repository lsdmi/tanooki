# frozen_string_literal: true

# Records the current chapter in the user's reading progress.
class ReadingProgressTracker
  attr_reader :chapter, :user

  def initialize(chapter:, user:)
    @chapter = chapter
    @user = user
  end

  def call
    return unless user

    progress = ReadingProgress.find_or_initialize_by(fiction_id: chapter.fiction.id, user_id: user.id)
    progress.chapter_id = chapter.id
    progress.save
  end
end
