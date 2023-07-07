# frozen_string_literal: true

module LibraryHelper
  def ordered_chapters(fiction)
    fiction.chapters.order(:number, :created_at)
  end

  def chapters_size(fiction)
    ordered_chapters(fiction).size
  end

  def next_chapter(fiction, chapter)
    fiction.chapters.where(
      'number > ? OR (number = ? AND created_at > ?)', chapter.number, chapter.number, chapter.created_at
    ).order(:number).first
  end

  def read_chapters(fiction, chapter)
    ordered_chapters(fiction).index(chapter) + 1
  end
end
