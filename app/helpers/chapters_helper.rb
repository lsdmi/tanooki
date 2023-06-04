# frozen_string_literal: true

module ChaptersHelper
  def chapter_header(chapter)
    "Розділ #{chapter.number} #{"- #{chapter.title}" if chapter.title.present?}"
  end
end
