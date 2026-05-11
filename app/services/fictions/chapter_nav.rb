# frozen_string_literal: true

module Fictions
  # Next chapter and ordered slices for the fiction show reader (per translator / duplicate chapters).
  class ChapterNav
    include LibraryHelper

    attr_reader :fiction, :reading_progress, :translator_id, :viewer

    def initialize(fiction, reading_progress, translator_id, viewer = nil)
      @fiction = fiction
      @reading_progress = reading_progress
      @translator_id = translator_id
      @viewer = viewer
    end

    def translator
      chapters[-1]&.scanlators&.ids
    end

    def before_next_chapter
      return nil if following_chapter_index.nil?

      fiction_chapters[0...following_chapter_index + 1]
    end

    def before_next_chapter_by_user
      idx = next_chapter_index(fiction_chapters, next_chapter)
      return nil if idx.nil?

      idx == -1 ? [] : fiction_chapters[0...idx + 1]
    end

    def next_chapter
      return first_chapter unless reading_progress.present?

      following_chapter(
        reading_progress.chapter.fiction,
        reading_progress.chapter,
        viewer:
      ) || first_chapter
    end

    private

    def chapters
      ordered_chapters_desc(fiction, viewer:)
    end

    def fiction_chapters
      if duplicate_chapters(fiction).any?
        chapters.select { |chapter| chapter.scanlators.ids.join('-') == translator.join('-') }
      else
        chapters
      end
    end

    def first_chapter
      ordered_chapters(fiction, viewer:).first
    end

    def following_chapter_index
      fiction_chapters.index(next_chapter)
    end
  end
end
