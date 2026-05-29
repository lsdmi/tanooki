# frozen_string_literal: true

module Chapters
  # Composes chapter list, EPUB, and form helpers for views that need the full chapter UI toolkit.
  module PresentationHelper
    include EpubDownloadHelper
    include FormHelper
    include ListSectionsHelper
  end
end
