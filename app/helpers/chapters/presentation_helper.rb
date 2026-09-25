# frozen_string_literal: true

module Chapters
  # Composes chapter list, EPUB, and form helpers for views that need the full chapter UI toolkit.
  module PresentationHelper
    include EpubDownloadHelper
    include FormHelper
    include ListSectionsHelper

    # Action Text already sanitizes chapter HTML; the reader only normalizes nbsp and tags resume blocks.
    def reader_chapter_content(chapter)
      Chapters::ReaderContentHtml.new(chapter)
    end
  end
end
