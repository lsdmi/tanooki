# frozen_string_literal: true

module Reading
  # Chapter keys (`ReadingChapterRead.chapter_key`) the user has read in a fiction: the sparse read set, plus,
  # on library rows that predate the rebuild, every listed chapter up to and including the old pointer.
  class ReadKeys
    def self.call(user:, fiction:, progress:)
      new(user:, fiction:, progress:).call
    end

    def initialize(user:, fiction:, progress:)
      @user = user
      @fiction = fiction
      @progress = progress
    end

    def call
      ReadingChapterRead.read_keys(user: @user, fiction: @fiction).merge(legacy_chapter_ids.keys)
    end

    # Key => id of the first listed translation, for every chapter the legacy snapshot covers.
    # Unscoped: a deleted pointer translation still marks the place in the list by its key.
    def legacy_chapter_ids
      chapter_id = @progress&.legacy_read_through_chapter_id
      return {} unless chapter_id

      pointer = Chapter.unscoped.where(id: chapter_id).pick(:volume_number, :number)
      listed = listed_chapter_ids
      index = pointer && listed.keys.index(pointer)
      index ? listed.first(index + 1).to_h : {}
    end

    private

    def listed_chapter_ids
      Library::ChapterCatalog.ordered_chapters(@fiction, viewer: @user)
                             .pluck(:volume_number, :number, :id)
                             .each_with_object({}) { |(volume, number, id), ids| ids[[volume, number]] ||= id }
    end
  end
end
