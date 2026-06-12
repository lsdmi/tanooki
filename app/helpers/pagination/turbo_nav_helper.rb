# frozen_string_literal: true

module Pagination
  # Pagy nav markup with optional Turbo Frame targets and GET form page buttons.
  module TurboNavHelper
    include Pagy::Frontend

    def pagy_nav_with_turbo_frame(pagy, frame_id = 'tab-content')
      render_pagination_component(pagy, frame_id: frame_id, turbo_stream: true)
    end

    def pagy_nav_buttons(pagy, pagy_id: 'pagy', frame_id: nil, aria_label: 'Сторінок', custom_params: {})
      render_pagination_component(
        pagy,
        pagy_id: pagy_id,
        frame_id: frame_id,
        aria_label: aria_label,
        custom_params: custom_params
      )
    end

    private

    def render_pagination_component(pagy, **options)
      render_to_string(Ui::PaginationComponent.new(pagy: pagy, **options))
    end
  end
end
