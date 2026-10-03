# frozen_string_literal: true

module Chapters
  # EPUB download affordances in chapter and fiction views.
  module EpubDownloadHelper
    def chapters_allow_epub_download?(chapters)
      Books::EpubDownloadPermission.allowed?(chapters)
    end

    def epub_download_available?(chapters)
      chapters_allow_epub_download?(chapters) && user_signed_in?
    end

    def epub_download_requires_login?(chapters)
      chapters_allow_epub_download?(chapters) && !user_signed_in?
    end
  end
end
