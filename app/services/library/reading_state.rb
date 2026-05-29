# frozen_string_literal: true

module Library
  # Reading status labels and EPUB download support for a fiction's listable chapters.
  module ReadingState
    STATUSES = {
      'Читаю' => :active,
      'Прочитано' => :finished,
      'Відкладено' => :postponed,
      'Покинуто' => :dropped
    }.freeze

    module_function

    def status_filters
      STATUSES
    end

    def status_label_for(status)
      STATUSES.key(status)
    end

    def fiction_epub_download_support(fiction, viewer: nil)
      list = ChapterCatalog.ordered_chapters(fiction, viewer: viewer).includes(:scanlators).to_a
      return :none if list.empty?

      allowed = list.count { |chapter| Books::EpubDownloadPermission.allowed?([chapter]) }
      return :all if allowed == list.size
      return :none if allowed.zero?

      :mixed
    end
  end
end
