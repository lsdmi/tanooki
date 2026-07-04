# frozen_string_literal: true

module Fictions
  # Text overlay for fiction index / genre showcase carousel slides.
  # Mobile (< sm): tag, title, and description only — bottom-aligned, no metadata or CTAs.
  class ShowcaseSlideOverlayComponent < ViewComponent::Base
    include Fictions::FormattingHelper
    include Layout::TurboDriveHelper
    include Ui::ComponentHelper

    LAYOUTS = %i[responsive mobile_minimal full].freeze

    GHOST_BUTTON_CLASSES = 'shrink-0 !border-white/50 !bg-transparent !text-white hover:!border-white ' \
                           'hover:!bg-white/10 hover:!text-white dark:!border-white/40 dark:!bg-transparent ' \
                           'dark:!text-white dark:hover:!border-white/70 dark:hover:!bg-white/10'

    def initialize(fiction:, editorial_kinds:, links:, eager_link_preload: false, layout: :responsive)
      super()
      @fiction = fiction
      @editorial_kinds = editorial_kinds
      @read_href = links.fetch(:read)
      @fiction_href = links.fetch(:fiction)
      @eager_link_preload = eager_link_preload
      @layout = layout.to_sym
      validate!
    end

    private

    attr_reader :fiction, :editorial_kinds, :read_href, :fiction_href, :eager_link_preload, :layout

    def validate!
      raise ArgumentError, "unknown layout: #{layout}" unless LAYOUTS.include?(layout)
    end

    def mobile_minimal?
      layout == :mobile_minimal
    end

    def full?
      layout == :full
    end

    def wrapper_classes
      [
        'z-10 min-w-0 w-full transition-all duration-700 ease-in-out absolute left-0',
        position_classes,
        width_classes
      ].join(' ')
    end

    def position_classes
      if mobile_minimal?
        'bottom-0 pl-4 pr-8 pb-10'
      elsif full?
        'top-1/2 -translate-y-1/2 px-4 md:px-12'
      else
        'max-sm:top-auto max-sm:bottom-0 max-sm:translate-y-0 max-sm:pl-4 max-sm:pr-8 max-sm:pb-10 ' \
          'top-1/2 -translate-y-1/2 px-4 md:px-12'
      end
    end

    def width_classes
      if mobile_minimal?
        'max-w-[min(30rem,calc(100%-2rem))]'
      elsif full?
        'max-w-[min(40rem,calc(100%-3rem))] lg:max-w-[min(50rem,calc(100%-3rem))]'
      else
        'max-w-[min(30rem,calc(100%-2rem))] md:max-w-[min(40rem,calc(100%-3rem))] lg:max-w-[min(50rem,calc(100%-3rem))]'
      end
    end

    def tag_list_classes
      mobile_minimal? ? 'mb-3' : 'max-sm:mb-3 mb-4'
    end

    def title_classes
      base = 'font-extrabold tracking-tight leading-tight text-white drop-shadow-lg'

      case layout
      when :mobile_minimal
        "#{base} mb-2 text-2xl line-clamp-1"
      when :full
        "#{base} mb-2 md:mb-4 text-2xl md:text-4xl lg:text-5xl line-clamp-1"
      else
        "#{base} mb-2 md:mb-4 text-2xl md:text-4xl lg:text-5xl line-clamp-1 max-sm:line-clamp-1"
      end
    end

    def description_classes
      [
        'font-medium leading-snug text-white/90 drop-shadow-md tracking-tight',
        mobile_minimal? ? 'text-sm line-clamp-2' : 'text-sm md:text-base line-clamp-2 md:line-clamp-3'
      ].join(' ')
    end

    def metadata_wrapper_classes
      base = 'flex flex-wrap items-center gap-x-3 gap-y-1.5 text-sm md:text-base text-white/90'

      case layout
      when :mobile_minimal then 'hidden'
      when :full then base
      else "max-sm:hidden #{base}"
      end
    end

    def buttons_wrapper_classes
      base = 'flex flex-wrap items-center gap-3'

      case layout
      when :mobile_minimal then 'hidden'
      when :full then base
      else "max-sm:hidden #{base}"
      end
    end

    def ghost_button_classes
      GHOST_BUTTON_CLASSES
    end

    def rating_label
      fiction.average_rating.positive? ? helpers.number_with_precision(fiction.average_rating, precision: 1) : '—'
    end
  end
end
