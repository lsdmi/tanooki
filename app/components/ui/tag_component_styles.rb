# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::TagComponent variants and sizes.
  module TagComponentStyles
    OUTLINED_CLASSES = [
      'border border-gray-300 bg-white text-gray-800',
      'hover:bg-gray-50',
      'dark:border-zinc-500 dark:bg-gray-900 dark:text-gray-200 dark:hover:bg-gray-800'
    ].join(' ').freeze

    FILTER_CLASSES = [
      'border border-cyan-800 bg-cyan-700 text-white hover:bg-cyan-800',
      'dark:border-rose-400 dark:bg-rose-600 dark:hover:bg-rose-700 dark:text-white'
    ].join(' ').freeze

    # Adult: rose-200 fill, rose-700 border, rose-800 label/icon (light + dark)
    ADULT_CLASSES = [
      'border border-rose-700 bg-rose-200 text-rose-800',
      'hover:bg-rose-300 hover:text-rose-900 hover:border-rose-800',
      'focus-visible:ring-rose-600'
    ].join(' ').freeze

    SIZE_CLASSES = {
      sm: 'rounded-lg px-2.5 py-0.5 text-xs font-normal',
      md: 'rounded-lg px-3 py-1 text-sm font-normal md:rounded-xl'
    }.freeze

    INTERACTIVE_CLASSES = [
      'transition-colors focus:outline-none focus-visible:ring-2',
      'focus-visible:ring-cyan-500 focus-visible:ring-offset-2',
      'dark:focus-visible:ring-rose-400 dark:focus-visible:ring-offset-gray-900'
    ].join(' ').freeze

    COUNT_SIZE_CLASSES = {
      sm: 'min-w-[1.25rem] px-1 py-px text-[10px] leading-4',
      md: 'min-w-[1.5rem] px-1.5 py-0.5 text-xs leading-4'
    }.freeze
  end
end
