# frozen_string_literal: true

module Library
  # Reading status and EPUB support helpers for library views.
  module ReadingStateHelper
    include ChapterCatalogHelper
    include ChapterNavigationHelper
    include Chapters::EpubDownloadHelper

    delegate :status_filters, :status_label_for, to: ReadingState

    def fiction_epub_download_support(fiction, viewer: nil)
      ReadingState.fiction_epub_download_support(fiction, viewer: viewer)
    end
  end
end
