# frozen_string_literal: true

module Ui
  # Primary / secondary / ghost button or link with shared cyan (light) and rose (dark) tokens.
  class ButtonComponent < ViewComponent::Base
    include ButtonComponentStyles

    VARIANTS = %i[primary secondary ghost].freeze
    SIZES = %i[xs sm md lg xl icon].freeze
    ELEMENT_TYPES = %i[button link submit].freeze

    def initialize(label: nil, variant: :primary, size: :md, as: :button, **options)
      super()
      @label = label
      @variant = variant.to_sym
      @size = size.to_sym
      @as = as.to_sym
      @href = options[:href]
      @full_width = options.fetch(:full_width, false)
      @disabled = options.fetch(:disabled, false)
      @html = options.fetch(:html, {})
      validate!
    end

    def render?
      label.present? || content?
    end

    private

    attr_reader :label, :variant, :size, :as, :href, :full_width, :disabled, :html

    def validate!
      raise ArgumentError, "unknown variant: #{variant}" unless VARIANTS.include?(variant)
      raise ArgumentError, "unknown size: #{size}" unless SIZES.include?(size)
      raise ArgumentError, "unknown as: #{as}" unless ELEMENT_TYPES.include?(as)
      raise ArgumentError, 'href is required when as: :link' if link? && href.blank?
    end

    def link?
      as == :link
    end

    def submit?
      as == :submit
    end

    def button_type
      submit? ? 'submit' : 'button'
    end

    def element_attributes
      attrs = { class: merged_css_classes }
      apply_disabled_attributes!(attrs)
      attrs.merge!(html.except(:class))
    end

    def merged_css_classes
      [css_classes, html[:class]].compact.join(' ')
    end

    def apply_disabled_attributes!(attrs)
      return unless disabled

      if link?
        attrs[:aria] = { disabled: true }
        attrs[:tabindex] = -1
      else
        attrs[:disabled] = true
      end
    end

    def css_classes
      [
        BASE_CLASSES,
        SIZE_CLASSES.fetch(size),
        VARIANT_CLASSES.fetch(variant),
        ('w-full' if full_width)
      ].compact.join(' ')
    end
  end
end
