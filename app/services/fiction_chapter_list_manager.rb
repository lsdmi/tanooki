# frozen_string_literal: true

class FictionChapterListManager
  include LibraryHelper

  attr_reader :fiction, :reading_progress, :translator_id

  def initialize(fiction, reading_progress, translator_id)
    @fiction = fiction
    @reading_progress = reading_progress
    @translator_id = translator_id
  end

  def translator
    chapters.first.scanlators.ids
  end

  def before_next_chapter
    return nil if following_chapter_index.nil?

    fiction_chapters[0...following_chapter_index + 1]
  end

  def before_next_chapter_by_user
    return nil if next_chapter_index_by_user.nil?

    next_chapter_index_by_user == -1 ? [] : fiction_chapters[0...next_chapter_index_by_user + 1]
  end

  def next_chapter
    return first_chapter unless reading_progress.present?

    following_chapter(
      reading_progress.chapter.fiction,
      reading_progress.chapter
    ) || first_chapter
  end

  private

  def chapters
    ordered_chapters_desc(fiction)
  end

  def fiction_chapters
    if duplicate_chapters(fiction).any?
      chapters.select { |chapter| chapter.scanlators.ids.join('-') == translator_id.join('-') }
    else
      chapters
    end
  end

  def first_chapter
    ordered_chapters(fiction).first
  end

  def following_chapter_index
    fiction_chapters.index(next_chapter)
  end

  def next_chapter_index_by_user
    next_chapter_index(fiction_chapters, next_chapter)
  end
end
