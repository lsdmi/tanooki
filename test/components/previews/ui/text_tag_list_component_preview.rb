# frozen_string_literal: true

module Ui
  class TextTagListComponentPreview < ViewComponent::Preview
    # @label Fiction tags as text
    def variants
      render_with_template(template: 'ui/text_tag_list_component_preview/variants')
    end
  end
end
