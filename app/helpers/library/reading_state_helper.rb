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

    # Guests' fiction page CTA is cached for everyone, so `guest-continue` swaps in «Продовжити» from the reading
    # record on their device. It needs the latest listable chapter to tell «Все прочитано» (keep «Читати»).
    def guest_continue_data(fiction, first_chapter)
      latest_id = ChapterCatalog.chapters_scope_for_list(fiction, nil).order(ChapterCatalog.order_clause_desc).pick(:id)
      {
        controller: 'guest-continue',
        guest_continue_fiction_id_value: fiction.id,
        guest_continue_latest_chapter_id_value: latest_id,
        guest_continue_read_path_value: chapter_path(first_chapter),
        guest_continue_read_label_value: t('fictions.read_cta.read'),
        guest_continue_continue_label_value: t('fictions.read_cta.continue')
      }
    end
  end
end
