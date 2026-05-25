# frozen_string_literal: true

# Chapter navigation helpers for previous/next reader links.
module LibraryChapterNavigationHelper
  def previous_chapter(fiction, chapter, viewer: nil)
    find_adjacent_chapter(fiction, chapter, :previous, viewer:)
  end

  def following_chapter(fiction, chapter, viewer: nil)
    find_adjacent_chapter(fiction, chapter, :next, viewer:)
  end

  def chapter_index(chapters, chapter)
    chapters.index { |obj| obj.number == chapter.number && obj.volume_number == chapter.volume_number } || 0
  end

  def unique_chapters(chapters)
    chapters.to_a.uniq { |obj| [obj.number, obj.volume_number] }
  end

  private

  def find_adjacent_chapter(fiction, chapter, direction, viewer: nil)
    chapters = unique_chapters(ordered_chapters_desc(fiction, viewer:))
    index = chapter_index(chapters, chapter)

    return nil if index.nil?

    adjacent_index = calculate_adjacent_index(index, direction)
    return nil if invalid_index?(adjacent_index, chapters.size)

    find_matching_chapter(fiction, chapters[adjacent_index], chapter.user_id, viewer:)
  end

  def calculate_adjacent_index(index, direction)
    direction == :previous ? index + 1 : index - 1
  end

  def invalid_index?(index, size)
    index.negative? || index >= size
  end

  def find_matching_chapter(fiction, adjacent_chapter, user_id, viewer: nil)
    ordered_chapters_desc(fiction, viewer:).find_by(
      number: adjacent_chapter.number,
      volume_number: adjacent_chapter.volume_number,
      user_id:
    ) || adjacent_chapter
  end
end
