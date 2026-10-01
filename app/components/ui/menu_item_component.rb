# frozen_string_literal: true

module Ui
  # Row in a dropdown or bottom sheet menu (Figma «Menu item», 10147:10715). Pass a 16 px icon through the `icon` slot.
  class MenuItemComponent < ViewComponent::Base
    ELEMENT_TYPES = %i[button submit link].freeze

    BASE_CLASSES = [
      'flex min-h-9 w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm transition-colors',
      'focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-line-strong'
    ].join(' ').freeze
    TONE_CLASSES = {
      default: 'text-fg hover:bg-surface-hover',
      selected: 'bg-brand-subtle text-fg-brand',
      destructive: 'text-status-danger-solid hover:bg-status-danger-subtle-bg'
    }.freeze

    renders_one :icon

    def initialize(label:, tone: :default, as: :button, href: nil, html: {})
      super()
      @label = label
      @tone = tone.to_sym
      @as = as.to_sym
      @href = href
      @html = html
      raise ArgumentError, "unknown tone: #{tone}" unless TONE_CLASSES.key?(@tone)
      raise ArgumentError, "unknown as: #{as}" unless ELEMENT_TYPES.include?(@as)
      raise ArgumentError, 'href is required when as: :link' if link? && href.blank?
    end

    private

    attr_reader :label, :tone, :href, :html

    def link?
      @as == :link
    end

    def selected?
      tone == :selected
    end

    def button_type
      @as == :submit ? 'submit' : 'button'
    end

    def element_attributes
      attributes = html.except(:class, :aria)
      attributes[:class] = [BASE_CLASSES, TONE_CLASSES.fetch(tone), html[:class]].compact.join(' ')
      aria = html.fetch(:aria, {}).merge(selected? ? { current: true } : {})
      attributes[:aria] = aria if aria.present?
      attributes
    end
  end
end
