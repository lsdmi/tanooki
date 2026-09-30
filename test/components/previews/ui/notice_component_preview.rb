# frozen_string_literal: true

module Ui
  class NoticeComponentPreview < ViewComponent::Preview
    # @label Kinds and styles
    def kinds
      render_with_template(template: 'ui/notice_component_preview/kinds')
    end
  end
end
