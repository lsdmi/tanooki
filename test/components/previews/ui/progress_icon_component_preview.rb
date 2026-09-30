# frozen_string_literal: true

module Ui
  class ProgressIconComponentPreview < ViewComponent::Preview
    # @label States and sizes
    def states
      render_with_template(template: 'ui/progress_icon_component_preview/states')
    end
  end
end
