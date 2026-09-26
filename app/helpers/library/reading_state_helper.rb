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

    def continue_reading_for(reading, viewer: current_user)
      ContinueReadingPresenter.new(reading, viewer:)
    end

    # Fiction page «Продовжити»: the same chapter as the library «Читати далі». Nil without a resume cursor or once
    # everything is read, so the page keeps «Читати» from the first chapter.
    def fiction_continue_reading(reading, viewer: current_user)
      return unless reading

      continue = continue_reading_for(reading, viewer:)
      continue if continue.continue_chapter && !continue.all_read?
    end
  end
end
