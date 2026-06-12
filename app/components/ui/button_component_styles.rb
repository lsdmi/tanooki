# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::ButtonComponent variants and sizes.
  module ButtonComponentStyles
    BASE_CLASSES = 'inline-flex items-center justify-center gap-1.5 transition-colors duration-200 ' \
                   'focus:outline-none disabled:pointer-events-none disabled:opacity-50'

    VARIANT_CLASSES = {
      primary: [
        'border border-cyan-800 bg-cyan-700 text-white font-medium shadow-sm',
        'hover:bg-cyan-800 hover:shadow-md',
        'focus-visible:ring-2 focus-visible:ring-cyan-500 focus-visible:ring-offset-2',
        'dark:border-rose-400 dark:bg-rose-600 dark:text-white dark:hover:bg-rose-700',
        'dark:focus-visible:ring-rose-400 dark:focus-visible:ring-offset-gray-900'
      ].join(' ').freeze,
      ghost: [
        'border border-stone-200 bg-transparent text-stone-700 font-medium',
        'hover:border-stone-300 hover:text-stone-900',
        'focus-visible:ring-2 focus-visible:ring-stone-400 focus-visible:ring-offset-2',
        'dark:border-zinc-600 dark:bg-transparent dark:text-zinc-200',
        'dark:hover:border-zinc-600 dark:hover:text-white',
        'dark:focus-visible:ring-zinc-500 dark:focus-visible:ring-offset-zinc-900'
      ].join(' ').freeze
    }.freeze

    SIZE_CLASSES = {
      xs: 'rounded px-2.5 py-0.5 text-xs font-medium',
      md: 'rounded-lg px-5 py-2.5 text-sm font-medium',
      icon: 'rounded-full p-4 text-sm font-medium shadow-lg hover:scale-110 focus:ring-offset-2',
      responsive: [
        'rounded px-2.5 py-0.5 text-xs font-medium',
        'md:rounded-lg md:px-5 md:py-2.5 md:text-sm'
      ].join(' ').freeze
    }.freeze
  end
end
