# frozen_string_literal: true

module Fictions
  # Mikai-style: centered type over a full-slide page-color veil.
  # Light mode → dark ink on a light wash; dark mode → white ink on a dark wash (same as mikai).
  module ShowcaseSlideOverlayComponentStyles
    def wrapper_classes
      [
        'pointer-events-none absolute inset-0 z-[2] flex items-center justify-center',
        'pt-14 pb-20 md:pt-16 md:pb-20',
        rail? ? 'mx-auto w-full max-w-[1300px] px-4' : 'w-full px-4'
      ].join(' ')
    end

    def stack_classes
      'pointer-events-auto flex w-full max-w-3xl flex-col items-center gap-3 px-2 text-center xl:px-0 md:gap-4'
    end

    def tag_list_classes
      'mb-0 justify-center'
    end

    def title_classes
      'text-balance text-2xl/tight font-semibold tracking-tight text-fg ' \
        'dark:text-white sm:text-3xl/tight md:text-4xl/tight line-clamp-2'
    end

    def title_link_classes
      'token-raw underline-offset-[0.22em] decoration-transparent decoration-2 ' \
        'transition-[color,text-decoration-color,opacity] duration-200 ' \
        'hover:underline hover:decoration-fg/40 hover:opacity-90 ' \
        'dark:hover:decoration-white/45'
    end

    def description_classes
      base = 'max-w-2xl text-pretty text-sm/5 text-fg-secondary line-clamp-2 ' \
             'dark:text-white/80 sm:text-base/6'

      case layout
      when :full then base
      else "max-sm:hidden #{base}"
      end
    end

    def metadata_classes
      base = 'flex flex-wrap items-center justify-center gap-x-4 gap-y-1.5 text-sm/5'

      case layout
      when :mobile_minimal then 'hidden'
      when :full then base
      else "max-sm:hidden #{base}"
      end
    end

    def meta_rating_classes
      'inline-flex items-center gap-1 font-semibold text-amber-500'
    end

    def meta_muted_classes
      'inline-flex min-w-0 items-center gap-1.5 text-fg-secondary dark:text-white/90'
    end

    def meta_icon_classes
      'h-4 w-4 shrink-0'
    end

    def read_link_classes
      'mb-6 inline-flex w-fit items-center gap-1.5 text-sm/5 font-medium text-fg-secondary ' \
        'underline-offset-4 transition-colors hover:text-fg hover:underline ' \
        'dark:text-white/90 dark:hover:text-white'
    end
  end
end
