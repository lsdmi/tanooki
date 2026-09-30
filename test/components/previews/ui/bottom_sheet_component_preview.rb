# frozen_string_literal: true

module Ui
  class BottomSheetComponentPreview < ViewComponent::Preview
    # Resize below 768 px to see the bottom sheet (drag the handle down, tap the scrim or press Esc to close).
    # @label Shelf picker and chapter actions
    def menus
      render_with_template(template: 'ui/bottom_sheet_component_preview/menus')
    end
  end
end
