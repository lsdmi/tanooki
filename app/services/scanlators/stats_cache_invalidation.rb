# frozen_string_literal: true

module Scanlators
  # Drops cached scanlator show stats when underlying records change.
  class StatsCacheInvalidation
    def self.for_scanlator_ids(scanlator_ids)
      ShowPresenter.invalidate_for_scanlators(scanlator_ids)
    end

    def self.for_chapter(chapter)
      for_scanlator_ids(chapter.scanlator_ids)
    end

    def self.for_fiction(fiction)
      return if fiction.nil?

      for_scanlator_ids(fiction.scanlators.ids)
    end
  end
end
