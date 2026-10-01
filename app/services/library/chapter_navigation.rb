# frozen_string_literal: true

module Library
  # Previous/next chapter links for the reader and related navigation.
  module ChapterNavigation
    module_function

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

    def find_adjacent_chapter(fiction, chapter, direction, viewer: nil)
      listed = ChapterCatalog.listed_chapters(fiction, viewer:)
      chapters = unique_chapters(listed)
      adjacent_index = calculate_adjacent_index(chapter_index(chapters, chapter), direction)
      return nil if invalid_index?(adjacent_index, chapters.size)

      find_matching_chapter(listed, chapters[adjacent_index], chapter.user_id)
    end
    module_function :find_adjacent_chapter

    def calculate_adjacent_index(index, direction)
      direction == :previous ? index + 1 : index - 1
    end
    module_function :calculate_adjacent_index

    def invalid_index?(index, size)
      index.negative? || index >= size
    end
    module_function :invalid_index?

    # Same translator as the current chapter when they also posted the adjacent one.
    def find_matching_chapter(listed, adjacent_chapter, user_id)
      listed.find do |chapter|
        chapter.number == adjacent_chapter.number &&
          chapter.volume_number == adjacent_chapter.volume_number &&
          chapter.user_id == user_id
      end || adjacent_chapter
    end
    module_function :find_matching_chapter
  end
end
