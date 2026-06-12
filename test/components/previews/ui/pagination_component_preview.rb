# frozen_string_literal: true

module Ui
  class PaginationComponentPreview < ViewComponent::Preview
    # @label Pagination
    def default
      render_with_template(template: 'ui/pagination_component_preview/default')
    end
  end
end
