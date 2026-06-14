# frozen_string_literal: true

module Fictions
  # Pagy custom params for fiction-list Turbo frames; sanitized via Fictions::ListFilters.
  module ListPaginationHelper
    def fiction_list_pagy_custom_params
      Fictions::ListFilters.permit_for_pagy(params)
    end
  end
end
