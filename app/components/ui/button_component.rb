# frozen_string_literal: true

module Ui
  # Button or link in the Figma «Buttons» variants. Icon-only buttons use `label` as the accessible name.
  class ButtonComponent < ViewComponent::Base
    include ButtonComponentStyles

    VARIANTS = %i[primary outline ghost destructive licensed on_media].freeze
    SIZES = %i[xs sm md lg fab responsive responsive_banner].freeze
    ELEMENT_TYPES = %i[button link submit].freeze

    def initialize(label: nil, variant: :primary, size: :lg, as: :button, **options)
      super()
      @label = label
      @variant = variant.to_sym
      @size = size.to_sym
      @as = as.to_sym
      assign_options(options)
      validate!
    end

    def render?
      icon_only ? content? : label.present? || content?
    end

    private

    attr_reader :label, :variant, :size, :as, :href, :full_width, :icon_only, :loading, :disabled, :html

    def assign_options(options)
      @href = options[:href]
      @full_width = options.fetch(:full_width, false)
      @icon_only = options.fetch(:icon_only, false)
      @loading = options.fetch(:loading, false)
      @disabled = options.fetch(:disabled, false)
      @html = options.fetch(:html, {})
    end

    def validate!
      validate_choice!(:variant, variant, VARIANTS)
      validate_choice!(:size, size, SIZES)
      validate_choice!(:as, as, ELEMENT_TYPES)
      raise ArgumentError, 'href is required when as: :link' if link? && href.blank?

      validate_icon_only! if icon_only
    end

    def validate_choice!(name, value, allowed)
      raise ArgumentError, "unknown #{name}: #{value}" unless allowed.include?(value)
    end

    def validate_icon_only!
      raise ArgumentError, 'label is required for icon_only buttons' if label.blank?
      return if ICON_ONLY_SIZE_CLASSES.key?(size)

      raise ArgumentError, "icon_only needs size :sm, :md or :lg, got #{size}"
    end

    def link?
      as == :link
    end

    def submit?
      as == :submit
    end

    def inert?
      loading || disabled
    end

    def show_content?
      content? && !(icon_only && loading)
    end

    def shadow?
      size != :fab && UNSHADOWED_VARIANTS.exclude?(variant)
    end

    def button_type
      submit? ? 'submit' : 'button'
    end

    def element_attributes
      attributes = html.except(:class, :aria)
      attributes[:class] = merged_css_classes
      attributes[:aria] = aria_attributes if aria_attributes.present?
      attributes[:disabled] = true if inert? && !link?
      attributes[:tabindex] = -1 if inert? && link?
      attributes
    end

    def aria_attributes
      @aria_attributes ||= html.fetch(:aria, {}).dup.tap do |aria|
        aria[:label] ||= label if icon_only
        aria[:busy] = true if loading
        aria[:disabled] = true if inert? && link?
      end
    end

    def merged_css_classes
      [css_classes, html[:class]].compact.join(' ')
    end

    def css_classes
      [
        BASE_CLASSES,
        icon_only ? ICON_ONLY_SIZE_CLASSES.fetch(size) : SIZE_CLASSES.fetch(size),
        VARIANT_CLASSES.fetch(variant),
        (SHADOW_CLASSES if shadow?),
        ('w-full' if full_width),
        (INERT_LINK_CLASSES if inert? && link?)
      ].compact.join(' ')
    end
  end
end
