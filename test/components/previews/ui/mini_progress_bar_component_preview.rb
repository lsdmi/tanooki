# frozen_string_literal: true

module Ui
  class MiniProgressBarComponentPreview < ViewComponent::Preview
    # @label States and widths
    def states
      render_with_template(template: 'ui/mini_progress_bar_component_preview/states')
    end
  end
end
