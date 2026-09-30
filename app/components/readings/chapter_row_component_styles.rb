# frozen_string_literal: true

module Readings
  # Shared Tailwind classes for Readings::ChapterRowComponent variants.
  module ChapterRowComponentStyles
    ICON_WRAPPER_CLASSES = 'h-10 w-10 rounded-lg bg-brand-subtle flex items-center justify-center'
    ICON_CLASSES = 'h-5 w-5 text-fg-brand'
    STAT_ICON_CLASSES = 'h-4 w-4 text-fg-brand'
    DELETE_ICON_PATH = [
      'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6',
      'm1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16'
    ].join.freeze

    VIEW_ACTION_CLASSES = [
      'inline-flex h-8 w-8 items-center justify-center rounded-lg',
      'text-fg-brand hover:text-fg-brand-hover',
      'transition-colors duration-200'
    ].join(' ').freeze

    EDIT_ACTION_CLASSES = [
      'inline-flex h-8 w-8 items-center justify-center rounded-lg',
      'text-fg-muted hover:text-fg',
      'transition-colors duration-200'
    ].join(' ').freeze

    CARD_TITLE_CLASSES = [
      'block hover:text-fg-brand transition-colors duration-200',
      'font-medium text-fg'
    ].join(' ').freeze
    TABLE_TITLE_CLASSES = 'hover:text-fg-brand transition-colors duration-200 font-medium'

    DELETE_ACTION_CLASSES = [
      'inline-flex h-8 w-8 items-center justify-center rounded-lg',
      'text-status-danger-solid hover:text-status-danger-solid',
      'transition-colors duration-200'
    ].join(' ').freeze
  end
end
