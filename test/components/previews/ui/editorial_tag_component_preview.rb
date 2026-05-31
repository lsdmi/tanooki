# frozen_string_literal: true

module Ui
  class EditorialTagComponentPreview < ViewComponent::Preview
    # @label All kinds
    def hero_kinds
      render_with_template(template: 'ui/editorial_tag_component_preview/hero_kinds')
    end
  end
end
