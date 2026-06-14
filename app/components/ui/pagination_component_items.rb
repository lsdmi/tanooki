# frozen_string_literal: true

module Ui
  # Nav item builders for Ui::PaginationComponent.
  module PaginationComponentItems
    include PaginationComponentStyles

    private

    def page_item(page, label:, aria_label: nil, rounded: nil)
      return current_page_item(label, rounded) if page == pagy.page
      return button_page_item(page, label, aria_label, rounded) if onclick

      form_page_item(page, label, aria_label, rounded)
    end

    def current_page_item(label, rounded)
      { type: :current, label: label.to_s, css_class: rounded_class(CURRENT_CLASSES, rounded) }
    end

    def button_page_item(page, label, aria_label, rounded)
      {
        type: :button,
        label: label.to_s,
        css_class: rounded_class(PAGE_CLASSES, rounded),
        onclick: onclick.call(page),
        aria_label: aria_label
      }
    end

    def form_page_item(page, label, aria_label, rounded)
      {
        type: :form,
        label: label.to_s,
        page: page,
        css_class: rounded_class(PAGE_CLASSES, rounded),
        aria_label: aria_label
      }
    end

    def gap_item(label)
      { type: :gap, label: label, css_class: GAP_CLASSES }
    end

    def rounded_class(base, rounded)
      [base, rounded_corner_class(rounded)].compact.join(' ')
    end

    def rounded_corner_class(rounded)
      case rounded
      when :left then 'rounded-l-md'
      when :right then 'rounded-r-md'
      end
    end

    def form_options(item)
      options = {
        method: :get,
        params: custom_params.merge(page: item[:page]),
        form: turbo_form_options,
        class: item[:css_class]
      }
      options[:'aria-label'] = item[:aria_label] if item[:aria_label]
      options
    end

    def turbo_form_options
      return {} if frame_id.blank?

      data = { turbo_frame: frame_id }
      data[:turbo_stream] = true if turbo_stream
      { data: data }
    end
  end
end
