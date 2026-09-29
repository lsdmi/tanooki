# frozen_string_literal: true

module Chapters
  # Fiction chapter drawer: counts, progress, and searchable chapter index.
  module ChapterDrawerHelper
    # Only :read rows are washed and muted. The resume chapter stands out by weight and its marker, never the wash.
    DRAWER_TITLE_CLASSES = {
      current: 'text-sm font-medium text-cyan-900 dark:text-rose-200',
      in_progress: 'text-sm font-medium text-stone-900 dark:text-zinc-50',
      read: 'text-sm text-stone-500 dark:text-zinc-400',
      unread: 'text-sm text-stone-800 dark:text-zinc-200'
    }.freeze
    LIST_TITLE_CLASSES = {
      current: 'font-medium text-stone-900 dark:text-gray-100',
      in_progress: 'font-medium text-stone-900 dark:text-gray-100',
      read: 'text-stone-500 dark:text-gray-400',
      unread: 'text-stone-700 group-hover:text-stone-900 dark:text-gray-300 dark:group-hover:text-gray-100'
    }.freeze
    DRAWER_ROW_CLASSES = {
      read: 'bg-stone-50 hover:bg-stone-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800/70',
      other: 'hover:bg-stone-50 dark:hover:bg-zinc-800/60'
    }.freeze
    LIST_ROW_CLASSES = {
      read: 'bg-stone-50 hover:bg-stone-100 dark:bg-gray-800/60 dark:hover:bg-gray-700',
      other: 'hover:bg-stone-50 dark:hover:bg-gray-700'
    }.freeze

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

    # Unread stays unlabelled, as in `_reader_chapter_drawer_status`.
    def reader_chapter_drawer_status_labels
      %i[read current in_progress].index_with { t("chapters.reader_chapter_drawer.progress_#{it}") }
    end

    def chapter_row_title_class(status, reader_drawer:)
      (reader_drawer ? DRAWER_TITLE_CLASSES : LIST_TITLE_CLASSES).fetch(status)
    end

    def chapter_row_class(status, reader_drawer:)
      classes = reader_drawer ? DRAWER_ROW_CLASSES : LIST_ROW_CLASSES
      status == :read ? classes[:read] : classes[:other]
    end

    def reader_chapter_drawer_search_index(fiction, order:, current_chapter: nil, viewer: current_user)
      chapters = drawer_chapters_for_order(fiction, order:, viewer:)
      drawer_progress = reader_chapter_drawer_progress(fiction, current_chapter:, viewer:)

      chapters.map { |chapter| drawer_chapter_entry(chapter, drawer_progress) }
    end

    def drawer_chapters_for_order(fiction, order:, viewer:)
      if order.to_sym == :desc
        ordered_chapters_desc(fiction, viewer: viewer)
      else
        ordered_chapters(fiction, viewer: viewer)
      end
    end

    def drawer_chapter_entry(chapter, drawer_progress)
      {
        id: chapter.id,
        number: chapter.number,
        title: chapter.display_title_no_volume,
        url: chapter_path(chapter),
        status: drawer_progress.status_for(chapter)
      }
    end
  end
end
