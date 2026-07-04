# frozen_string_literal: true

module Chapters
  # Composes chapter list, EPUB, and form helpers for views that need the full chapter UI toolkit.
  module PresentationHelper
    include EpubDownloadHelper
    include FormHelper
    include ListSectionsHelper

    def reader_chapter_content(chapter)
      # Action Text already sanitizes chapter HTML; we only normalize nbsp for wrapping.
      Chapters::ReaderContentHtml.render(chapter).html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
