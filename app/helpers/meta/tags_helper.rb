# frozen_string_literal: true

module Meta
  # Composes page meta tag helpers (title, description, robots, image, Open Graph type).
  module TagsHelper
    include Layout::PageContextHelper
    include Meta::ExcerptHelper
    include Meta::DescriptionHelper
    include Meta::AssignsHelper
    include Meta::TitleHelper
    include Meta::RobotsHelper
    include Meta::CoverSelectionHelper
    include Meta::ImageHelper
    include Meta::OpenGraphHelper
  end
end
