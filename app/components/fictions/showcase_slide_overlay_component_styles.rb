# frozen_string_literal: true

module Fictions
  # Tailwind classes for ShowcaseSlideOverlayComponent layout variants.
  module ShowcaseSlideOverlayComponentStyles
    GHOST_BUTTON_CLASSES = 'shrink-0 !border-white/50 !bg-transparent !text-white hover:!border-white ' \
                           'hover:!bg-white/10 hover:!text-white dark:!border-white/40 dark:!bg-transparent ' \
                           'dark:!text-white dark:hover:!border-white/70 dark:hover:!bg-white/10'

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
        'w-full'
      elsif full?
        'max-w-[min(40rem,calc(100%-3rem))] lg:max-w-[min(50rem,calc(100%-3rem))]'
      else
        'sm:max-w-[min(30rem,calc(100%-2rem))] md:max-w-[min(40rem,calc(100%-3rem))] ' \
          'lg:max-w-[min(50rem,calc(100%-3rem))]'
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

    def body_wrapper_classes
      case layout
      when :mobile_minimal
        'space-y-0'
      when :full
        'mb-4 md:mb-8 flex flex-col gap-4'
      else
        'max-sm:mb-0 max-sm:space-y-0 sm:mb-4 md:mb-8 sm:flex sm:flex-col sm:gap-4'
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
  end
end
