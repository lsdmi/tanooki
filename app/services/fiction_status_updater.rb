# frozen_string_literal: true

class FictionStatusUpdater
  def initialize(fiction)
    @fiction = fiction
  end

  def call
    return if @fiction.finished?

    last_chapter_time = @fiction.chapters.maximum(:created_at)
    return if last_chapter_time.nil? || (Time.current - last_chapter_time) < 90.days

    @fiction.update_column(:status, Fiction.statuses[:dropped])
  end
end
