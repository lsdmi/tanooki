# frozen_string_literal: true

module Fictions
  # Removes one scanlator team's chapters and fiction link from a shared fiction.
  class ScanlatorAssociationRemover
    def initialize(fiction, scanlator)
      @fiction = fiction
      @scanlator = scanlator
    end

    def call
      scanlator_chapters.destroy_all
      fiction_scanlator&.destroy
    end

    private

    attr_reader :fiction, :scanlator

    def scanlator_chapters
      fiction.chapters.joins(:scanlators).where(chapter_scanlators: { scanlator_id: scanlator.id })
    end

    def fiction_scanlator
      FictionScanlator.find_by(fiction_id: fiction.id, scanlator_id: scanlator.id)
    end
  end
end
