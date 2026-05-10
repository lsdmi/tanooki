# frozen_string_literal: true

# Search index pagination: keep Pagy link params aligned with SearchController and Brakeman-safe.
module SearchHelper
  VALID_SEARCH_FILTERS = %w[fiction blog video].freeze

  def search_index_pagy_custom_params(section)
    permitted = params.permit(:filter, search: [])
    filter = permitted[:filter].to_s
    filter = nil unless VALID_SEARCH_FILTERS.include?(filter)

    { search: permitted[:search], filter:, section: }.compact
  end

  def search_index_pagy_nav_html(pagy, frame_id:, section:)
    pagy_nav_buttons(
      pagy,
      frame_id:,
      custom_params: search_index_pagy_custom_params(section)
    )
  end
end
