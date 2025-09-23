# frozen_string_literal: true

module LibraryHelper
  STATUSES = {
    'Читаю' => :active,
    'Прочитано' => :finished,
    'Відкладено' => :postponed,
    'Покинуто' => :dropped
  }.freeze

  def status_filters
    STATUSES
  end

  def status_label_for(status)
    status_filters.key(status)
  end

  def ordered_chapters(fiction)
    fiction.chapters.order(order_clause)
  end

  def ordered_chapters_desc(fiction)
    fiction.chapters.order(order_clause_desc)
  end

  def ordered_user_chapters_desc(fiction, user)
    chapters = ordered_chapters_desc(fiction)
    return chapters if user.admin?

    chapters.joins(:scanlators).where(scanlators: { id: user.scanlators.ids }).distinct
  end

  def chapters_size(fiction)
    unique_chapters(ordered_chapters(fiction)).size
  end

  def duplicate_chapters(fiction)
    Rails.cache.fetch("duplicate_chapters/#{fiction.id}/#{fiction.chapters.maximum(:updated_at)}",
                      expires_in: 1.hour) do
      # Group chapters by number and check if there are multiple scanlator combinations
      chapter_groups = fiction.chapters.includes(:scanlators).group_by(&:number)

      duplicated_numbers = chapter_groups.select do |_number, chapters|
        # Get unique scanlator combinations for this chapter number
        scanlator_combinations = chapters.map { |chapter| chapter.scanlators.pluck(:id).sort }.uniq
        scanlator_combinations.size > 1
      end

      # Return chapters that belong to duplicated numbers
      duplicated_chapter_numbers = duplicated_numbers.keys
      fiction.chapters.where(number: duplicated_chapter_numbers)
    end
  end

  def grouped_chapters_desc(fiction)
    ordered_chapters_desc(fiction).joins(:scanlators).group_by { |chapter| chapter.scanlators.pluck(:id).sort }
  end

  def previous_chapter(fiction, chapter)
    find_adjacent_chapter(fiction, chapter, :previous)
  end

  def following_chapter(fiction, chapter)
    find_adjacent_chapter(fiction, chapter, :next)
  end

  def chapter_index(chapters, chapter)
    chapters.index { |obj| obj.number == chapter.number && obj.volume_number == chapter.volume_number } || 0
  end

  def next_chapter_index(chapters, chapter)
    chapters.rindex do |obj|
      (chapter.volume_number || 0) <= (obj.volume_number || 0) && chapter.number <= obj.number
    end || -1
  end

  def unique_chapters(chapters)
    chapters.to_a.uniq { |obj| [obj.number, obj.volume_number] }
  end

  private

  def order_clause
    Arel.sql('CASE WHEN volume_number IS NULL OR volume_number = 0 THEN number ELSE volume_number END, number, chapters.created_at')
  end

  def order_clause_desc
    Arel.sql('COALESCE(volume_number, 0) DESC, number DESC, chapters.created_at DESC')
  end

  def find_adjacent_chapter(fiction, chapter, direction)
    chapters = unique_chapters(ordered_chapters_desc(fiction))
    index = chapter_index(chapters, chapter)

    return nil if index.nil?

    adjacent_index = calculate_adjacent_index(index, direction)
    return nil if invalid_index?(adjacent_index, chapters.size)

    find_matching_chapter(fiction, chapters[adjacent_index], chapter.user_id)
  end

  def calculate_adjacent_index(index, direction)
    direction == :previous ? index + 1 : index - 1
  end

  def invalid_index?(index, size)
    index.negative? || index >= size
  end

  def find_matching_chapter(fiction, adjacent_chapter, user_id)
    ordered_chapters_desc(fiction).find_by(
      number: adjacent_chapter.number,
      volume_number: adjacent_chapter.volume_number,
      user_id:
    ) || adjacent_chapter
  end
end
