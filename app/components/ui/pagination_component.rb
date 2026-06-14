# frozen_string_literal: true

module Ui
  # Pagy pagination nav styled like the /translate requests list.
  class PaginationComponent < ViewComponent::Base
    include PaginationComponentStyles
    include PaginationComponentItems

    DEFAULT_OPTIONS = {
      pagy_id: 'pagy',
      aria_label: 'Сторінок',
      custom_params: {},
      turbo_stream: false,
      html: {}
    }.freeze

    def initialize(pagy:, **options)
      super()
      @pagy = pagy
      assign_options(DEFAULT_OPTIONS.merge(options))
    end

    def render?
      pagy.pages > 1
    end

    def pagination_path
      form_path || request.path
    end

    private

    attr_reader :pagy, :pagy_id, :aria_label, :frame_id, :custom_params, :form_path, :onclick, :turbo_stream, :html

    def assign_options(options)
      @pagy_id = options[:pagy_id]
      @aria_label = options[:aria_label]
      @frame_id = options[:frame_id]
      @custom_params = options[:custom_params]
      @form_path = options[:form_path]
      @onclick = options[:onclick]
      @turbo_stream = options[:turbo_stream]
      @html = options[:html]
    end

    def wrapper_classes
      [html[:class], 'flex justify-center'].compact.join(' ')
    end

    def wrapper_attributes
      html.except(:class).merge(class: wrapper_classes)
    end

    def nav_items
      [prev_item, *series_items, next_item].compact
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
      when Integer then page_item(item, label: item.to_s)
      when String then item.to_i.to_s == item ? page_item(item.to_i, label: item) : gap_item(item)
      when :gap then gap_item('…')
      end
    end
  end
end
