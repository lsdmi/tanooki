# frozen_string_literal: true

module UiHelper
  def ui_button(label = nil, **options, &block)
    render(Ui::ButtonComponent.new(label: label, **options), &block)
  end
end
