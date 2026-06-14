# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::PaginationComponent (translate page style).
  module PaginationComponentStyles
    PAGE_CLASSES = [
      'px-3 py-2 text-sm font-medium',
      'text-gray-900 dark:text-gray-100',
      'bg-white dark:bg-gray-700',
      'border border-gray-300 dark:border-gray-500',
      'hover:bg-gray-50 dark:hover:bg-gray-600',
      'transition-colors duration-200'
    ].join(' ').freeze

    CURRENT_CLASSES = [
      'px-3 py-2 text-sm font-medium',
      'text-white bg-cyan-700 dark:bg-rose-800',
      'border border-cyan-800 dark:border-rose-800',
      'cursor-default pointer-events-none'
    ].join(' ').freeze

    GAP_CLASSES = 'px-3 py-2 text-sm font-medium text-gray-400 dark:text-gray-400 cursor-default'
  end
end
