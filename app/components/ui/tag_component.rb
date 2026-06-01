# frozen_string_literal: true

module Ui
  # Taxonomy / keyword tag (genres, news tags, video keywords).
  # Keyword: neutral outline. Filter: primary (cyan light / red dark). Adult: red.
  # Light filled borders darker than fill; dark filled borders lighter than fill.
  class TagComponent < ViewComponent::Base
    include TagComponentStyles

    VARIANTS = %i[keyword genre status filter adult].freeze
    SIZES = %i[sm md].freeze

    def initialize(label:, variant: :keyword, size: :sm, **options)
      super()
      assign_options(label, variant, size, options)
      validate!
    end

    def render?
      label.present?
    end

    private

    attr_reader :label, :variant, :size, :as, :href, :current, :count, :html

    def assign_options(label, variant, size, options)
      @label = label.to_s
      @variant = variant.to_sym
      @size = size.to_sym
      @as = options.fetch(:as, :link).to_sym
      @href = options[:href]
      @current = options.fetch(:current, false)
      @count = options[:count]
      @html = options.fetch(:html, {})
    end

    def validate!
      raise ArgumentError, "unknown variant: #{@variant}" unless VARIANTS.include?(@variant)
      raise ArgumentError, "unknown size: #{@size}" unless SIZES.include?(@size)
      raise ArgumentError, "unknown as: #{@as}" unless %i[link button span].include?(@as)
    end

    def count?
      !count.nil?
    end

    def button?
      as == :button
    end

    def interactive?
      (as == :link && href.present?) || button?
    end

    def tag_attributes
      attrs = { class: css_classes }
      attrs[:aria] = { current: 'page' } if current
      attrs.merge!(html.except(:class))
      attrs[:class] = [attrs[:class], html[:class]].compact.join(' ')
      attrs
    end

    def css_classes
      [
        'inline-flex w-fit items-center whitespace-nowrap',
        (count? ? 'gap-1.5' : nil),
        size_classes,
        variant_classes,
        (INTERACTIVE_CLASSES if interactive?)
      ].compact.join(' ')
    end

    def size_classes
      base = SIZE_CLASSES.fetch(size)
      return base unless count?

      base.sub('px-2.5', 'pl-2.5 pr-1').sub('px-3', 'pl-3 pr-1.5')
    end

    def count_classes
      [
        'inline-flex items-center justify-center rounded-md font-medium tabular-nums',
        COUNT_SIZE_CLASSES.fetch(size),
        count_variant_classes
      ].join(' ')
    end

    def count_variant_classes
      if solid_variant? || variant == :adult
        'bg-white/25 text-white'
      else
        'bg-cyan-100 text-cyan-700 dark:bg-zinc-600 dark:text-zinc-100'
      end
    end

    def solid_variant?
      variant == :filter || (variant.in?(%i[keyword genre status]) && current)
    end

    def variant_classes
      case variant
      when :filter then FILTER_CLASSES
      when :adult then ADULT_CLASSES
      when :keyword, :genre, :status
        current ? FILTER_CLASSES : OUTLINED_CLASSES
      end
    end
  end
end
