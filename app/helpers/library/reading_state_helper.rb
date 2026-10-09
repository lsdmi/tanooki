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

    # Guests' fiction page CTA is cached for everyone, so `guest-continue` swaps in «Продовжити» from the reading
    # record on their device. It needs the latest listable chapter to tell «Все прочитано» (keep «Читати»).
    # The record has no chapter number, so the guest label is «Продовжити» without one.
    def guest_continue_data(fiction, first_chapter, read_label:)
      listed = ChapterCatalog.chapters_scope_for_list(fiction, nil)
      {
        controller: 'guest-continue',
        guest_continue_fiction_id_value: fiction.id,
        guest_continue_latest_chapter_id_value: listed.order(ChapterCatalog.order_clause_desc).pick(:id),
        guest_continue_read_path_value: chapter_path(first_chapter),
        guest_continue_read_label_value: read_label,
        guest_continue_continue_label_value: t('fictions.hero.cta.continue_guest')
      }.merge(guest_continue_listed_ids(fiction, listed))
    end

    # After a licence takedown the device record may sit on a hidden chapter, so only listed ids count.
    def guest_continue_listed_ids(fiction, listed)
      return {} unless fiction.license_chapters_state == :partial

      { guest_continue_listed_chapter_ids_value: listed.ids }
    end
  end
end
