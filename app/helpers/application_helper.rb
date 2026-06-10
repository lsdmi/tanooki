# frozen_string_literal: true

# Rails global helper entry point; composes namespaced view helpers.
module ApplicationHelper
  PRODUCTION_URL = Meta::CanonicalUrlHelper::PRODUCTION_URL

  include Chapters::CommentsDrawerHelper
  include Chapters::ReaderBottomHelper
  include Comments::PresentationHelper
  include ExternalUrls::UrlsHelper
  include Fictions::FormattingHelper
  include Layout::Helper
  include Meta::CanonicalUrlHelper
  include Meta::CoverUrlsHelper
  include Meta::TagsHelper
  include StructuredData::JsonLdHelper
end
