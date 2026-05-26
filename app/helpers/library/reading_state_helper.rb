# frozen_string_literal: true

module Library
  # Reading status and EPUB support helpers for library views.
  module ReadingStateHelper
    include LibraryChapterCatalogHelper
    include LibraryChapterNavigationHelper
    include ChaptersHelper

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

    def fiction_epub_download_support(fiction, viewer: nil)
      list = ordered_chapters(fiction, viewer: viewer).includes(:scanlators).to_a
      return :none if list.empty?

      allowed = list.count { |ch| chapter_epub_download_allowed?(ch) }
      return :all if allowed == list.size
      return :none if allowed.zero?

      :mixed
    end
  end
end
