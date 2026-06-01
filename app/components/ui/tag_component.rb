# frozen_string_literal: true

module Ui
  # Taxonomy / keyword tag (genres, news tags, video keywords).
  # Keyword: neutral outline. Filter: primary (cyan light / orange dark). Adult: red.
  # Light filled borders darker than fill; dark filled borders lighter than fill.
  class TagComponent < ViewComponent::Base
    VARIANTS = %i[keyword genre status filter adult].freeze
    SIZES = %i[sm md].freeze

    OUTLINED_CLASSES = [
      'border border-gray-300 bg-white text-gray-800',
      'hover:bg-gray-50',
      'dark:border-zinc-500 dark:bg-gray-900 dark:text-gray-200 dark:hover:bg-gray-800'
    ].join(' ').freeze

    FILTER_CLASSES = [
      'border border-cyan-800 bg-cyan-700 text-white hover:bg-cyan-800',
      'dark:border-orange-400 dark:bg-orange-600 dark:hover:bg-orange-700 dark:text-white'
    ].join(' ').freeze

    ADULT_CLASSES = [
      'border border-red-800 bg-red-600 text-white hover:bg-red-700',
      'dark:border-red-400 dark:bg-red-600 dark:hover:bg-red-700'
    ].join(' ').freeze

    SIZE_CLASSES = {
      sm: 'rounded-lg px-2.5 py-0.5 text-xs font-normal',
      md: 'rounded-lg px-3 py-1 text-sm font-normal md:rounded-xl'
    }.freeze

    INTERACTIVE_CLASSES = [
      'transition-colors focus:outline-none focus-visible:ring-2',
      'focus-visible:ring-cyan-500 focus-visible:ring-offset-2',
      'dark:focus-visible:ring-orange-400 dark:focus-visible:ring-offset-gray-900'
    ].join(' ').freeze

    COUNT_SIZE_CLASSES = {
      sm: 'min-w-[1.25rem] px-1 py-px text-[10px] leading-4',
      md: 'min-w-[1.5rem] px-1.5 py-0.5 text-xs leading-4'
    }.freeze

    def initialize(label:, variant: :keyword, size: :sm, **options)
      super()
      @label = label.to_s
      @variant = variant.to_sym
      @size = size.to_sym
      @href = options[:href]
      @current = options.fetch(:current, false)
      @count = options[:count]
      @html = options.fetch(:html, {})

      raise ArgumentError, "unknown variant: #{@variant}" unless VARIANTS.include?(@variant)
      raise ArgumentError, "unknown size: #{@size}" unless SIZES.include?(@size)
    end

    def render?
      label.present?
    end

    private

    attr_reader :label, :variant, :size, :href, :current, :count, :html

    def count?
      count.present?
    end

    def interactive?
      href.present?
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
