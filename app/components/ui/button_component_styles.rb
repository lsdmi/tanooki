# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::ButtonComponent variants and sizes.
  module ButtonComponentStyles
    BASE_CLASSES = 'inline-flex items-center justify-center gap-1.5 transition-colors duration-200 ' \
                   'focus:outline-none disabled:pointer-events-none disabled:opacity-50'

    VARIANT_CLASSES = {
      primary: [
        'border border-brand-hover bg-brand text-fg-on-brand font-medium shadow-sm',
        'hover:bg-brand-hover hover:shadow-md',
        'focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-main'
      ].join(' ').freeze,
      ghost: [
        'border border-line bg-transparent text-fg-secondary font-medium',
        'hover:border-line-strong hover:text-fg',
        'focus-visible:ring-2 focus-visible:ring-line-strong focus-visible:ring-offset-2 focus-visible:ring-offset-main'
      ].join(' ').freeze
    }.freeze

    SIZE_CLASSES = {
      xs: 'rounded px-2.5 py-0.5 text-xs font-medium',
      md: 'rounded-lg px-5 py-2.5 text-sm font-medium',
      icon: 'rounded-full p-4 text-sm font-medium shadow-lg hover:scale-110 focus:ring-offset-2',
      responsive: [
        'rounded px-2.5 py-0.5 text-xs font-medium',
        'md:rounded-lg md:px-5 md:py-2.5 md:text-sm'
      ].join(' ').freeze,
      responsive_banner: [
        'rounded-md px-4 py-1.5 text-xs font-medium',
        'md:rounded-lg md:px-5 md:py-2.5 md:text-sm'
      ].join(' ').freeze
    }.freeze
  end
end
