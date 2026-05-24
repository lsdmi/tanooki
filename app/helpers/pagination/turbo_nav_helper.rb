# frozen_string_literal: true

module Pagination
  # Pagy nav markup with optional Turbo Frame targets and GET form page buttons.
  module TurboNavHelper
    include Pagy::Frontend

    def pagy_nav_with_turbo_frame(pagy, frame_id = 'tab-content')
      pagy_nav(pagy).gsub('<a ', "<a data-turbo-frame=\"#{frame_id}\" data-turbo-stream=\"true\" ")
    end

    def pagy_nav_buttons(pagy, pagy_id: 'pagy', frame_id: nil, aria_label: 'Сторінок', custom_params: {})
      [
        pagy_nav_open(pagy_id, aria_label),
        pagy_prev_button(pagy, frame_id, custom_params),
        pagy_series_buttons(pagy, frame_id, custom_params),
        pagy_next_button(pagy, frame_id, custom_params),
        '</nav>'
      ].join
    end

    private

    def pagy_nav_open(pagy_id, aria_label)
      %(<nav id="#{pagy_id}" class="pagy nav" aria-label="#{aria_label}">)
    end

    def pagy_series_buttons(pagy, frame_id, custom_params)
      pagy.series.map { |item| pagy_series_item(item, pagy, frame_id, custom_params) }.join
    end

    def pagy_series_item(item, pagy, frame_id, custom_params)
      case item
      when Integer then pagy_page_button(item, pagy, frame_id, custom_params)
      when String
        if item.to_i.to_s == item
          pagy_page_button(item.to_i, pagy, frame_id, custom_params)
        else
          pagy_gap_span(item)
        end
      when :gap then pagy_gap_span
      end
    end

    def pagy_prev_button(pagy, frame_id, custom_params = {})
      if pagy.prev
        pagy_nav_link_button(
          label: '&lt;'.html_safe, page: pagy.prev, frame_id: frame_id, custom_params: custom_params,
          css_class: 'pagy-prev', aria_label: 'Назад'
        )
      else
        pagy_disabled_nav_button('pagy-prev', 'Назад', '&lt;')
      end
    end

    def pagy_next_button(pagy, frame_id, custom_params = {})
      if pagy.next
        pagy_nav_link_button(
          label: '&gt;'.html_safe, page: pagy.next, frame_id: frame_id, custom_params: custom_params,
          css_class: 'pagy-next', aria_label: 'Далі'
        )
      else
        pagy_disabled_nav_button('pagy-next', 'Далі', '&gt;')
      end
    end

    def pagy_page_button(page, pagy, frame_id, custom_params = {})
      if page == pagy.page
        %(<button role="link" aria-disabled="true" aria-current="page" class="current">#{page}</button>)
      else
        pagy_nav_link_button(label: page.to_s, page: page, frame_id: frame_id, custom_params: custom_params)
      end
    end

    def pagy_nav_link_button(config)
      options = {
        method: :get,
        params: config.fetch(:custom_params).merge(page: config.fetch(:page)),
        form: pagy_turbo_form_options(config[:frame_id])
      }
      options[:class] = config[:css_class] if config[:css_class]
      options[:'aria-label'] = config[:aria_label] if config[:aria_label]
      button_to(config.fetch(:label), request.path, **options)
    end

    def pagy_turbo_form_options(frame_id)
      frame_id ? { data: { turbo_frame: frame_id } } : {}
    end

    def pagy_disabled_nav_button(css_class, aria_label, label)
      %(<button role="link" aria-disabled="true" aria-label="#{aria_label}") +
        %( class="#{css_class} disabled">#{label}</button>)
    end

    def pagy_gap_span(text = '…')
      %(<button role="link" aria-disabled="true" class="gap">#{text}</button>)
    end
  end
end
