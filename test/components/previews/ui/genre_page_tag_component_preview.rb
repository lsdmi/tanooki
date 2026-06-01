# frozen_string_literal: true

module Ui
  class GenrePageTagComponentPreview < ViewComponent::Preview
    # @label Genre page tags
    def variants
      render_with_template(template: 'ui/genre_page_tag_component_preview/variants')
    end
  end
end
