# frozen_string_literal: true

# View helpers for chapter reader, forms, and catalog navigation.
module ChaptersViewHelpers
  extend ActiveSupport::Concern

  included do
    include Adsense::ChapterReaderHelper

    helper Adsense::ChapterReaderHelper,
           Chapters::ChapterDrawerHelper,
           Chapters::PresentationHelper,
           Chapters::ReaderSettingsHelper,
           Library::ChapterCatalogHelper,
           Library::ChapterNavigationHelper,
           Library::ReadingStateHelper,
           Scanlators::SelectOptionsHelper
  end
end
