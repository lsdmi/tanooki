# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::PaginationComponent (translate page style).
  module PaginationComponentStyles
    PAGE_CLASSES = [
      'px-3 py-2 text-sm font-medium',
      'text-fg',
      'bg-card dark:bg-surface-strong',
      'border border-line-strong',
      'hover:bg-surface-hover',
      'transition-colors duration-200'
    ].join(' ').freeze

    CURRENT_CLASSES = [
      'px-3 py-2 text-sm font-medium',
      'text-fg-on-brand bg-brand',
      'border border-brand-hover',
      'cursor-default pointer-events-none'
    ].join(' ').freeze

    GAP_CLASSES = 'px-3 py-2 text-sm font-medium text-fg-muted cursor-default'
  end
end
