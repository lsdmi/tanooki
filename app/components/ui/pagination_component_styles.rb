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

    # Quiet chips like the scanlator header stats — no brand fill.
    PILL_PAGE_CLASSES = [
      'token-raw rounded-lg px-3 py-2 text-sm font-medium text-fg',
      'token-raw border border-zinc-500 bg-white/40 backdrop-blur-sm',
      'token-raw hover:bg-white/70',
      'token-raw dark:border-zinc-400/80 dark:bg-zinc-950/35 dark:hover:bg-zinc-950/55',
      'transition-colors duration-200'
    ].join(' ').freeze

    PILL_CURRENT_CLASSES = [
      'token-raw rounded-lg px-3 py-2 text-sm font-semibold text-fg',
      'token-raw border-2 border-zinc-800 bg-white/90 shadow-sm backdrop-blur-sm',
      'token-raw dark:border-zinc-100 dark:bg-zinc-950/85',
      'cursor-default pointer-events-none'
    ].join(' ').freeze

    GAP_CLASSES = 'px-3 py-2 text-sm font-medium text-fg-muted cursor-default'
    PILL_GAP_CLASSES = 'rounded-lg px-3 py-2 text-sm font-medium text-fg-muted cursor-default'

    VARIANTS = %i[default pill].freeze
  end
end
