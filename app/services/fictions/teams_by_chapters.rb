# frozen_string_literal: true

module Fictions
  # Translation teams on a fiction, the one with more published chapters first.
  class TeamsByChapters
    def self.call(fiction)
      Library::RequestMemo.remember(:teams_by_chapters, fiction.id) { new(fiction).call }
    end

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      counts = chapter_counts
      @fiction.scanlators
              .select { |scanlator| counts[scanlator.id].to_i.positive? }
              .sort_by { |scanlator| [-counts[scanlator.id], scanlator.title.to_s] }
    end

    private

    def chapter_counts
      chapter_ids = Chapter.not_draft.where(fiction_id: @fiction.id).select(:id)
      ChapterScanlator.where(chapter_id: chapter_ids).group(:scanlator_id).count
    end
  end
end
