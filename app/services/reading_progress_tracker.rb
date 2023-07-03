# frozen_string_literal: true

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
