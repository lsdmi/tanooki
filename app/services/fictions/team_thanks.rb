# frozen_string_literal: true

module Fictions
  # Reader thanks on a fiction's published chapters, summed per translation team: { scanlator_id => count }.
  # A chapter shared by several teams counts for each of them.
  class TeamThanks
    def self.call(fiction)
      Library::RequestMemo.remember(:team_thanks, fiction.id) { new(fiction).call }
    end

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      Chapter.not_draft
             .where(fiction_id: @fiction.id)
             .joins(:chapter_scanlators)
             .group('chapter_scanlators.scanlator_id')
             .sum(:thanks_count)
    end
  end
end
