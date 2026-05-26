# frozen_string_literal: true

module Meta
  # Composes page meta tag helpers (title, description, image, Open Graph type).
  module TagsHelper
    include Meta::DescriptionHelper
    include Meta::AssignsHelper
    include Meta::TitleHelper
    include Meta::CoverHelper
    include Meta::ImageHelper
    include Meta::OpenGraphHelper
  end
end
