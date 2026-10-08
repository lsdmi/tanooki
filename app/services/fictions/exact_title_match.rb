# frozen_string_literal: true

module Fictions
  # Existing catalog fictions whose title, alternative title, or English title
  # normalizes to the same string as the title or English title being created.
  # Soft-deleted rows are already hidden by the default scope.
  class ExactTitleMatch
    def initialize(title:, english_title:)
      @needles = [title, english_title].filter_map { |value| DuplicateGroups.normalize(value).presence }.uniq
    end

    def call
      ids = ranked_match_ids
      return [] if ids.empty?

      loaded = Fiction.includes(:scanlators, cover_attachment: :blob).where(id: ids).index_by(&:id)
      ids.filter_map { |id| loaded[id] }
    end

    private

    attr_reader :needles

    def ranked_match_ids
      return [] if needles.empty?

      Fiction.pluck(:id, :title, :alternative_title, :english_title, :chapter_count)
             .select { |row| title_hit?(row) }
             .sort_by { |row| [-row.last, row.first] }
             .map(&:first)
    end

    def title_hit?(row)
      row[1..3].any? { |value| needles.include?(DuplicateGroups.normalize(value)) }
    end
  end
end
