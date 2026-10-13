# frozen_string_literal: true

module Chapters
  # Paragraphs that differ between a stored revision and the chapter as it is now.
  class RevisionChanges
    LIMIT = 12

    def self.for(chapter, revision)
      new(chapter, revision).payload
    end

    def initialize(chapter, revision)
      @chapter = chapter
      @revision = revision
    end

    def payload
      rows = changed_rows
      { rows: rows.first(LIMIT), hidden: hidden_count(rows), previous_title: }
    end

    private

    def changed_rows
      Api::Chapters::Diff.call(chapter, revision).reject { |row| row[:change] == 'same' }
    end

    def hidden_count(rows)
      [rows.size - LIMIT, 0].max
    end

    def previous_title
      revision.title if revision.title != chapter.title
    end

    attr_reader :chapter, :revision
  end
end
