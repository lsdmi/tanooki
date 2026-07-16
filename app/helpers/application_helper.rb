# frozen_string_literal: true

# Rails global helper entry point; composes namespaced view helpers.
module ApplicationHelper
  PRODUCTION_URL = Meta::CanonicalUrlHelper::PRODUCTION_URL

  include Pagination::PagyHelper
  include Chapters::CommentsDrawerHelper
  include Chapters::ReaderBottomHelper
  include Comments::PresentationHelper
  include ExternalUrls::UrlsHelper
  include Fictions::FormattingHelper
  include Layout::Helper
  include Meta::CanonicalUrlHelper
  include Meta::CoverUrlsHelper
  include Meta::TagsHelper
  include Root::PopularFictionsHelper
  include Root::RecentlyUpdatedHelper
  include Root::TalesHelper
  include Root::VideosHelper
  include StructuredData::JsonLdHelper
  include Ui::ComponentHelper
end
