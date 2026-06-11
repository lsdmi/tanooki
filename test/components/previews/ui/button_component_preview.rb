# frozen_string_literal: true

module Ui
  class ButtonComponentPreview < ViewComponent::Preview
    # @label Variants and sizes
    def variants
      render_with_template(template: 'ui/button_component_preview/variants')
    end
  end
end
