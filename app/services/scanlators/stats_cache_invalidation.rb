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
      for_scanlator_ids(fiction.scanlator_ids)
    end
  end
end
