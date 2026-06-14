# frozen_string_literal: true

module Pagination
  # Custom params for search index pagination; aligned with SearchController and Brakeman-safe.
  module SearchIndexHelper
    VALID_SEARCH_FILTERS = %w[fiction blog video].freeze

    def search_index_pagy_custom_params(section)
      permitted = params.permit(:filter, search: [])
      filter = permitted[:filter].to_s
      filter = nil unless VALID_SEARCH_FILTERS.include?(filter)

      { search: permitted[:search], filter:, section: }.compact
    end
  end
end
