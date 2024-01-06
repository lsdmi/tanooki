# frozen_string_literal: true

module LibraryHelper
  def ordered_chapters(fiction)
    fiction.chapters.order(
      Arel.sql(
        'CASE WHEN volume_number IS NULL OR volume_number = 0 THEN number ELSE volume_number END, number, created_at'
      )
    )
  end

  def ordered_chapters_desc(fiction)
    fiction.chapters.order(
      Arel.sql('COALESCE(volume_number, 0) DESC, number DESC, created_at DESC')
    )
  end

  def ordered_user_chapters_desc(fiction, user)
    user.admin? ? ordered_chapters_desc(fiction) : ordered_chapters_desc(fiction).joins(:scanlators).where(scanlators: { id: user.scanlators.ids })
  end

  def chapters_size(fiction)
    unique_chapters(ordered_chapters(fiction)).size
  end

  def duplicate_chapters(fiction)
    fiction.chapters.select('number').group('number').having('COUNT(DISTINCT user_id) > 1')
  end

  def grouped_chapters_desc(fiction)
    ordered_chapters_desc(fiction).joins(:scanlators).group_by { |chapter| chapter.scanlators.map(&:id).sort }
  end

  def following_chapter(fiction, chapter)
    chapters = unique_chapters(ordered_chapters_desc(fiction))
    index = chapter_index(chapters, chapter)

    return if index.nil? || !index.positive?

    following_chapter = chapters[index - 1]

    ordered_chapters_desc(fiction).find_by(
      number: following_chapter.number,
      volume_number: following_chapter.volume_number,
      user_id: chapter.user_id
    ) || following_chapter
  end

  def chapter_index(chapters, chapter)
    chapters.each_with_index do |obj, index|
      return index if obj.number == chapter.number && obj.volume_number == chapter.volume_number
    end

    0
  end

  def next_chapter_index(chapters, chapter)
    final_index = -1

    chapters.each_with_index do |obj, index|
      next if (chapter.volume_number || 0) > (obj.volume_number || 0)

      final_index = index if chapter.number <= obj.number
    end

    final_index
  end

  def unique_chapters(chapters)
    chapters.uniq { |obj| [obj.number, obj.volume_number] }
  end
end
