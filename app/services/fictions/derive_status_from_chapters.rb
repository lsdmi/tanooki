# frozen_string_literal: true

module Fictions
  # Derives fiction status from unique chapter release progress.
  class DeriveStatusFromChapters
    attr_reader :fiction_status, :expected_chapters, :unique

    def initialize(fiction)
      @fiction_status = fiction.status
      @expected_chapters = fiction.expected_chapters
      @unique = Library::ChapterNavigation.unique_chapters(fiction.chapters)
    end

    def call
      new_fiction_status
    end

    private

    def plan_met?
      expected_chapters.present? && unique.size >= expected_chapters
    end

    def announced_dropped_new_status
      plan_met? ? Fiction.statuses[:finished] : Fiction.statuses[:ongoing]
    end

    def ongoing_new_status
      plan_met? ? Fiction.statuses[:finished] : fiction_status
    end

    def new_fiction_status
      case Fiction.statuses[fiction_status]
      when Fiction.statuses[:announced], Fiction.statuses[:dropped], Fiction.statuses[:finished]
        announced_dropped_new_status
      else
        ongoing_new_status
      end
    end
  end
end
