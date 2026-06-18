# frozen_string_literal: true

module Readings
  # Table row or mobile card for a chapter on the readings (author studio) list.
  class ChapterRowComponent < ViewComponent::Base
    include ChapterRowComponentStyles
    include Layout::SweetAlertHelper

    VARIANTS = %i[table_row card].freeze

    def initialize(chapter:, variant: :table_row, pagy_page: 1)
      super()
      @chapter = chapter
      @variant = variant.to_sym
      @pagy_page = pagy_page
      validate!
    end

    private

    attr_reader :chapter, :variant, :pagy_page

    def validate!
      raise ArgumentError, "unknown variant: #{variant}" unless VARIANTS.include?(variant)
    end

    def table_row?
      variant == :table_row
    end

    def card?
      variant == :card
    end

    def published_at_label
      helpers.l(chapter.public_at.in_time_zone('Kyiv'), format: :short_datetime).downcase
    end

    def delete_url
      helpers.reading_path(chapter, page: pagy_page)
    end

    def render_actions
      render partial: 'readings/chapter_row_component/actions', locals: { chapter:, delete_button: }
    end

    def delete_button
      sweet_alert_button(
        delete_button_icon,
        description: 'Впевнені, що хочете видалити розділ?',
        message: '',
        tag_id: nil,
        url: delete_url,
        button_class: ChapterRowComponentStyles::DELETE_ACTION_CLASSES
      )
    end

    def delete_button_icon
      helpers.content_tag(
        :svg,
        delete_button_path,
        class: 'h-4 w-4',
        xmlns: 'http://www.w3.org/2000/svg',
        fill: 'none',
        viewBox: '0 0 24 24',
        stroke: 'currentColor',
        'aria-hidden': 'true'
      )
    end

    def delete_button_path
      helpers.content_tag(
        :path,
        nil,
        stroke_linecap: 'round',
        stroke_linejoin: 'round',
        stroke_width: '2',
        d: ChapterRowComponentStyles::DELETE_ICON_PATH
      )
    end
  end
end
