# frozen_string_literal: true

module Chapters
  # Fiction chapter drawer: counts, progress, and searchable chapter index.
  module ChapterDrawerHelper
    # Only :read rows are washed and muted. The resume chapter stands out by weight and its marker, never the wash.
    DRAWER_TITLE_CLASSES = {
      current: 'text-sm font-medium text-fg-brand-hover',
      in_progress: 'text-sm font-medium text-fg',
      read: 'text-sm text-fg-muted',
      unread: 'text-sm text-fg'
    }.freeze
    LIST_TITLE_CLASSES = {
      current: 'text-fg-brand',
      in_progress: 'text-fg-brand',
      read: 'text-fg-muted',
      unread: 'text-fg'
    }.freeze
    DRAWER_ROW_CLASSES = {
      read: 'bg-surface hover:bg-surface-strong dark:bg-surface/40 dark:hover:bg-surface/70',
      other: 'hover:bg-surface dark:hover:bg-surface/60'
    }.freeze
    # The fiction page tints only the continue row; read rows are told apart by the muted title and the check.
    LIST_ROW_CLASSES = {
      continue: 'bg-brand-subtle ring-1 ring-inset ring-brand',
      other: 'hover:bg-surface-hover'
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

    # :current shares the in-progress icon but keeps its own label; unread stays unlabelled.
    def chapter_progress_icon(status, size: :md)
      status = status.to_sym
      state = %i[read unread].include?(status) ? status : :in_progress
      label = t("chapters.reader_chapter_drawer.progress_#{status}") unless status == :unread
      render Ui::ProgressIconComponent.new(state:, label:, size:)
    end

    def chapter_row_title_class(status, reader_drawer:)
      (reader_drawer ? DRAWER_TITLE_CLASSES : LIST_TITLE_CLASSES).fetch(status)
    end

    def chapter_row_class(status, reader_drawer:)
      return DRAWER_ROW_CLASSES[status == :read ? :read : :other] if reader_drawer

      LIST_ROW_CLASSES[status.in?(%i[in_progress current]) ? :continue : :other]
    end

    def chapter_list_read_count(chapters, progress)
      progress.read_count(chapters.map { |chapter| ReadingChapterRead.chapter_key(chapter) }.uniq)
    end

    # Mobile rows drop «Розділ N —»: the number box already says it.
    def chapter_list_row_titles(chapter)
      number = Chapters::Formatting.format_decimal(chapter.number)
      return [t('fictions.chapters_tab.chapter', number:)] * 2 if chapter.title.blank?

      [chapter.title, t('fictions.chapters_tab.chapter_with_title', number:, title: chapter.title)]
    end

    def reader_chapter_drawer_search_index(fiction, order:, current_chapter: nil, viewer: current_user)
      chapters = Library::ChapterCatalog.listed_chapters(fiction, viewer:, order:)
      drawer_progress = reader_chapter_drawer_progress(fiction, current_chapter:, viewer:)

      chapters.map { |chapter| drawer_chapter_entry(chapter, drawer_progress) }
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
