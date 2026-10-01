# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::ButtonComponent variants and sizes (Figma «Buttons», 2093:8181).
  module ButtonComponentStyles
    BASE_CLASSES = [
      'inline-flex items-center justify-center gap-2 border font-medium',
      'transition-colors duration-200 focus:outline-none',
      'focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-main',
      'disabled:pointer-events-none disabled:opacity-50'
    ].join(' ').freeze

    # Each variant owns its border color: Tailwind orders same-property utilities by its own rules,
    # so a shared border-transparent in BASE_CLASSES could override border-line.
    VARIANT_CLASSES = {
      primary: 'border-transparent bg-brand text-fg-on-brand hover:bg-brand-hover focus-visible:ring-brand',
      outline: 'border-line bg-transparent text-fg hover:bg-surface focus-visible:ring-line-strong',
      ghost: 'border-transparent bg-transparent text-fg hover:bg-surface focus-visible:ring-line-strong',
      destructive: [
        'border-transparent bg-btn-destructive text-fg-on-brand',
        'hover:bg-btn-destructive-hover focus-visible:ring-btn-destructive'
      ].join(' ').freeze,
      licensed: [
        'border-transparent bg-btn-licensed text-fg-on-brand',
        'hover:bg-btn-licensed-hover focus-visible:ring-btn-licensed'
      ].join(' ').freeze,
      # White in both themes: it sits on the always-dark hero image.
      on_media: 'token-raw border-transparent bg-white text-slate-900 hover:bg-slate-100 focus-visible:ring-white'
    }.freeze

    SIZE_CLASSES = {
      xs: 'rounded px-2.5 py-0.5 text-xs',
      sm: 'min-h-8 rounded-lg px-3 py-1.5 text-xs',
      md: 'min-h-9 rounded-lg px-4 py-1.5 text-sm',
      lg: 'min-h-10 rounded-lg px-4 py-2 text-sm',
      fab: 'rounded-full p-4 text-sm shadow-lg hover:scale-110',
      responsive: [
        'rounded px-2.5 py-0.5 text-xs',
        'md:rounded-lg md:px-5 md:py-2.5 md:text-sm'
      ].join(' ').freeze,
      responsive_banner: [
        'rounded-md px-4 py-1.5 text-xs',
        'md:rounded-lg md:px-5 md:py-2.5 md:text-sm'
      ].join(' ').freeze
    }.freeze

    ICON_ONLY_SIZE_CLASSES = {
      sm: 'size-8 rounded-lg',
      md: 'size-9 rounded-lg',
      lg: 'size-10 rounded-lg'
    }.freeze

    # Figma's resting shadow; ghost has none and :fab brings its own shadow-lg.
    SHADOW_CLASSES = 'shadow-xs'
    UNSHADOWED_VARIANTS = %i[ghost].freeze

    INERT_LINK_CLASSES = 'pointer-events-none opacity-50'
    SPINNER_CLASSES = 'size-4 shrink-0 animate-spin'
  end
end
