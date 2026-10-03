# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::TagComponent variants and sizes.
  module TagComponentStyles
    OUTLINED_CLASSES = [
      'border border-line-strong bg-main text-fg',
      'hover:bg-surface'
    ].join(' ').freeze

    FILTER_CLASSES = 'border border-brand-hover bg-brand text-fg-on-brand hover:bg-brand-hover'

    # Adult tropes + 18+ rating: rose-200 fill, rose-700 border, rose-800 label/icon
    ADULT_CLASSES = [
      'token-raw border border-rose-700 bg-rose-200 text-rose-800',
      'token-raw hover:bg-rose-300 hover:text-rose-900 hover:border-rose-800',
      'token-raw focus-visible:ring-rose-600'
    ].join(' ').freeze

    # 16+ rating: amber fill distinct from rose 18+
    SIXTEEN_CLASSES = [
      'token-raw border border-amber-800 bg-amber-200 text-amber-900',
      'hover:bg-amber-300 hover:text-amber-950 hover:border-amber-900',
      'focus-visible:ring-amber-700'
    ].join(' ').freeze

    # snug: the 14 px label in a 24 px pill of the novel page (Figma «Keywords and Genre Tags» 8094:13866).
    SIZE_CLASSES = {
      sm: 'rounded-lg px-2.5 py-0.5 text-xs font-normal',
      snug: 'rounded-lg px-3 py-px text-sm/5 font-normal',
      md: 'rounded-lg px-3 py-1 text-sm font-normal md:rounded-xl'
    }.freeze

    INTERACTIVE_CLASSES = [
      'transition-colors focus:outline-none focus-visible:ring-2',
      'focus-visible:ring-fg-brand focus-visible:ring-offset-2 focus-visible:ring-offset-main'
    ].join(' ').freeze

    COUNT_SIZE_CLASSES = {
      sm: 'min-w-[1.25rem] px-1 py-px text-[10px] leading-4',
      snug: 'min-w-[1.25rem] px-1 py-px text-[10px] leading-4',
      md: 'min-w-[1.5rem] px-1.5 py-0.5 text-xs leading-4'
    }.freeze
  end
end
