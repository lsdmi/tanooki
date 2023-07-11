# frozen_string_literal: true

module LibraryHelper
  def ordered_chapters(fiction)
    fiction.chapters.order(:volume_number, :number, :created_at)
  end

  def ordered_chapters_desc(fiction)
    fiction.chapters.order(volume_number: :desc, number: :desc, created_at: :desc)
  end

  def chapters_size(fiction)
    ordered_chapters(fiction).size
  end

  def following_chapter(fiction, chapter)
    chapters = ordered_chapters_desc(fiction)
    index = chapters.index(chapter)
    chapters[index - 1] if index.present? && index.positive?
  end

  def read_chapters(fiction, chapter)
    ordered_chapters(fiction).index(chapter) + 1
  end
end
