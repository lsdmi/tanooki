# frozen_string_literal: true

module Fictions
  # Marks fictions as dropped when they look abandoned:
  # - ongoing: latest chapter older than 90 days
  # - announced: no chapters and created more than 90 days ago
  class InactivityDrop
    INACTIVITY = 90.days

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      if @fiction.ongoing?
        drop_stale_ongoing!
      elsif @fiction.announced?
        drop_never_started_announced!
      end
    end

    private

    def drop_stale_ongoing!
      last_chapter_time = @fiction.chapters.maximum(Arel.sql('COALESCE(published_at, created_at)'))
      return if last_chapter_time.nil? || (Time.current - last_chapter_time) < INACTIVITY

      mark_dropped!
    end

    def drop_never_started_announced!
      return if @fiction.chapters.exists?
      return if @fiction.created_at > INACTIVITY.ago

      mark_dropped!
    end

    def mark_dropped!
      @fiction.update!(status: Fiction.statuses[:dropped])
    end
  end
end
