# frozen_string_literal: true

module Ui
  # Pagy pagination nav styled like the /translate requests list.
  class PaginationComponent < ViewComponent::Base
    include PaginationComponentStyles

    def initialize(pagy:, pagy_id: 'pagy', aria_label: 'Сторінок', frame_id: nil, custom_params: {},
                   form_path: nil, onclick: nil, turbo_stream: false, html: {})
      super()
      @pagy = pagy
      @pagy_id = pagy_id
      @aria_label = aria_label
      @frame_id = frame_id
      @custom_params = custom_params
      @form_path = form_path
      @onclick = onclick
      @turbo_stream = turbo_stream
      @html = html
    end

    def render?
      pagy.pages > 1
    end

    def pagination_path
      form_path || request.path
    end

    private

    attr_reader :pagy, :pagy_id, :aria_label, :frame_id, :custom_params, :form_path, :onclick, :turbo_stream, :html

    def wrapper_classes
      [html[:class], 'flex justify-center'].compact.join(' ')
    end

    def wrapper_attributes
      html.except(:class).merge(class: wrapper_classes)
    end

    def nav_items
      [
        prev_item,
        *series_items,
        next_item
      ].compact
    end

    def prev_item
      return unless pagy.prev

      page_item(pagy.prev, label: '‹', aria_label: 'Назад', rounded: :left)
    end

    def next_item
      return unless pagy.next

      page_item(pagy.next, label: '›', aria_label: 'Далі', rounded: :right)
    end

    def series_items
      pagy.series.map { |item| series_item(item) }
    end

    def series_item(item)
      case item
      when Integer
        page_item(item, label: item.to_s)
      when String
        item.to_i.to_s == item ? page_item(item.to_i, label: item) : gap_item(item)
      when :gap
        gap_item('…')
      end
    end

    def page_item(page, label:, aria_label: nil, rounded: nil)
      if page == pagy.page
        { type: :current, label: label.to_s, css_class: rounded_class(CURRENT_CLASSES, rounded) }
      elsif onclick
        {
          type: :button,
          label: label.to_s,
          css_class: rounded_class(PAGE_CLASSES, rounded),
          onclick: onclick.call(page),
          aria_label: aria_label
        }
      else
        {
          type: :form,
          label: label.to_s,
          page: page,
          css_class: rounded_class(PAGE_CLASSES, rounded),
          aria_label: aria_label
        }
      end
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
