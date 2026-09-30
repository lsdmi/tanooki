# frozen_string_literal: true

module Ui
  # `showUndoToast` from flash_toast.js. The toast attaches to <body>, so use the theme toggle for dark mode.
  class UndoToastPreview < ViewComponent::Preview
    # @label Read, unread and bulk
    def variants
      render_with_template(template: 'ui/undo_toast_preview/variants')
    end
  end
end
