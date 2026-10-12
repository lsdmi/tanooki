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

      match_adjacent(listed, chapters[adjacent_index], chapter)
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

    # Stay with the current chapter's team, then with the same person, then the first translation of that slot.
    def match_adjacent(listed, adjacent, current)
      teams = team_ids_for(listed, current)
      slot = same_slot(listed, adjacent)
      same_team_member(slot, current, teams) || same_team(slot, current, teams) ||
        same_member(slot, current) || adjacent
    end
    module_function :match_adjacent

    def same_slot(listed, adjacent)
      listed.select { |chapter| chapter.number == adjacent.number && chapter.volume_number == adjacent.volume_number }
    end
    module_function :same_slot

    def same_team_member(slot, current, teams)
      slot.find { |chapter| share_team?(chapter, current, teams) && chapter.user_id == current.user_id }
    end
    module_function :same_team_member

    def same_team(slot, current, teams)
      slot.find { |chapter| share_team?(chapter, current, teams) }
    end
    module_function :same_team

    def same_member(slot, current)
      slot.find { |chapter| chapter.user_id == current.user_id }
    end
    module_function :same_member

    def share_team?(chapter, current, teams)
      teams[current.id].intersect?(teams[chapter.id])
    end
    module_function :share_team?

    def team_ids_for(listed, current)
      RequestMemo.remember(:chapter_team_ids, listed.object_id) do
        ids = listed.map(&:id)
        ids << current.id unless ids.include?(current.id)
        team_ids_by_chapter(ids)
      end
    end
    module_function :team_ids_for

    def team_ids_by_chapter(ids)
      rows = ChapterScanlator.where(chapter_id: ids).pluck(:chapter_id, :scanlator_id)
      rows.each_with_object(Hash.new { |map, key| map[key] = [] }) do |(chapter_id, team_id), map|
        map[chapter_id] << team_id
      end
    end
    module_function :team_ids_by_chapter
  end
end
