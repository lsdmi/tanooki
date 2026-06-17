# frozen_string_literal: true

module Chapters
  # Ensures each team on a chapter is also linked to the chapter's fiction.
  class LinkFictionScanlators
    def self.call(chapter:)
      new(chapter:).call
    end

    def initialize(chapter:)
      @chapter = chapter
    end

    def call
      return unless chapter.persisted?

      chapter.scanlators.ids.each do |scanlator_id|
        FictionScanlator.find_or_create_by!(fiction_id: chapter.fiction_id, scanlator_id:)
      end
    end

    private

    attr_reader :chapter
  end
end
