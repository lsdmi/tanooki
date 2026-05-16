# frozen_string_literal: true

module Fictions
  # Sets +dropped+ on non-finished fictions whose latest chapter activity is older than 90 days.
  class InactivityDrop
    def initialize(fiction)
      @fiction = fiction
    end

    def call
      return if @fiction.finished?

      last_chapter_time = @fiction.chapters.maximum(Arel.sql('COALESCE(published_at, created_at)'))
      return if last_chapter_time.nil? || (Time.current - last_chapter_time) < 90.days

      @fiction.update!(status: Fiction.statuses[:dropped])
    end
  end
end
