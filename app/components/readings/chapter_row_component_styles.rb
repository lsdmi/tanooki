# frozen_string_literal: true

module Readings
  # Shared Tailwind classes for Readings::ChapterRowComponent variants.
  module ChapterRowComponentStyles
    ICON_WRAPPER_CLASSES = 'h-10 w-10 rounded-lg bg-cyan-100 dark:bg-rose-900/20 flex items-center justify-center'
    ICON_CLASSES = 'h-5 w-5 text-cyan-700 dark:text-rose-400'
    STAT_ICON_CLASSES = 'h-4 w-4 text-cyan-700 dark:text-rose-400'
    DELETE_ICON_PATH = [
      'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6',
      'm1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16'
    ].join.freeze

    VIEW_ACTION_CLASSES = [
      'inline-flex h-8 w-8 items-center justify-center rounded-lg',
      'text-cyan-700 hover:text-cyan-700 dark:text-cyan-400 dark:hover:text-cyan-300',
      'transition-colors duration-200'
    ].join(' ').freeze

    EDIT_ACTION_CLASSES = [
      'inline-flex h-8 w-8 items-center justify-center rounded-lg',
      'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white',
      'transition-colors duration-200'
    ].join(' ').freeze

    DELETE_ACTION_CLASSES = [
      'inline-flex h-8 w-8 items-center justify-center rounded-lg',
      'text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300',
      'transition-colors duration-200'
    ].join(' ').freeze
  end
end
