# frozen_string_literal: true

# View helper for rendering Ui::ButtonComponent instances.
module UiHelper
  def ui_button(label = nil, **, &)
    render(Ui::ButtonComponent.new(label: label, **), &)
  end
end
