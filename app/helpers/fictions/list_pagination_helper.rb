# frozen_string_literal: true

module Fictions
  # Pagy nav for fiction-list Turbo frames; params sanitized via Fictions::ListFilters.
  module ListPaginationHelper
    def fiction_list_pagy_nav_html(pagy, frame_id: 'fiction-list-page', aria_label: 'Сторінок')
      pagy_nav_buttons(
        pagy,
        frame_id: frame_id,
        aria_label: aria_label,
        custom_params: fiction_list_pagy_custom_params
      )
    end

    def fiction_list_pagy_custom_params
      Fictions::ListFilters.permit_for_pagy(params)
    end
  end
end
