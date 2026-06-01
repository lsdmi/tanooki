# frozen_string_literal: true

module Ui
  class TagComponentPreview < ViewComponent::Preview
    # @label All variants
    def variants
      render_with_template(template: 'ui/tag_component_preview/variants')
    end
  end
end
