# frozen_string_literal: true

# Rails global helper entry point; composes namespaced view helpers.
module ApplicationHelper
  PRODUCTION_URL = Meta::CanonicalUrlHelper::PRODUCTION_URL

  include Chapters::ReaderBottomHelper
  include Meta::CanonicalUrlHelper
  include Layout::AdultContentHelper
  include ExternalUrls::UrlsHelper
  include Layout::PageContextHelper
  include Layout::StylesheetsHelper
  include Search::TagCountsHelper
  include Adsense::ChapterReaderHelper
end
