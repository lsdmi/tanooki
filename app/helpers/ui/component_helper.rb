# frozen_string_literal: true

module Ui
  # Renders Ui::* ViewComponents from views.
  module ComponentHelper
    def ui_button(label = nil, **, &)
      render(Ui::ButtonComponent.new(label: label, **), &)
    end

    def ui_pagination(pagy, **)
      render(Ui::PaginationComponent.new(pagy: pagy, **))
    end
  end
end
