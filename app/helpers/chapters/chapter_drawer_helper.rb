# frozen_string_literal: true

module Chapters
  module ChapterDrawerHelper
    def fiction_chapter_drawer_count(fiction, viewer: current_user)
      count = chapters_size(fiction, viewer: viewer)
      I18n.t('chapters.reader_chapter_drawer.fiction_chapters_count', count: count)
    end

    def reader_drawer_section_title(section)
      section[:title]
    end

    def reader_chapter_drawer_progress(fiction, current_chapter: nil, viewer: current_user)
      Reading::ChapterDrawerProgress.build(fiction:, viewer:, current_chapter:)
    end

    def reader_drawer_chapter_status(chapter, drawer_progress:)
      drawer_progress.status_for(chapter)
    end

    def reader_chapter_drawer_search_index(fiction, order:, current_chapter: nil, viewer: current_user)
      chapters = order.to_sym == :desc ? ordered_chapters_desc(fiction, viewer: viewer) : ordered_chapters(fiction, viewer: viewer)
      drawer_progress = reader_chapter_drawer_progress(fiction, current_chapter:, viewer:)

      chapters.map do |chapter|
        status = drawer_progress.status_for(chapter)
        {
          id: chapter.id,
          number: chapter.number,
          title: chapter.display_title_no_volume,
          url: chapter_path(chapter),
          current: status == :current,
          status: status
        }
      end
    end
  end
end
