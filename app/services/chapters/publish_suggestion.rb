# frozen_string_literal: true

module Chapters
  # The publish moment a new chapter can copy from the fiction's latest chapter.
  # Only a moment still ahead is suggested: a past time would fail Chapter's published_at validation.
  class PublishSuggestion
    def self.call(fiction)
      return if fiction.nil?

      # Same order as Chapter.ordered_by_volume_and_number, newest first (Rails cannot reverse raw SQL order).
      latest = fiction.chapters
                      .order(Arel.sql("COALESCE(volume_number, 0) DESC, number DESC, #{Chapter::PUBLIC_TIME_SQL} DESC"))
                      .first
      moment = latest&.published_at
      moment if moment&.future?
    end
  end
end
