# frozen_string_literal: true

module Chapters
  # Tailwind for the chapter-end thanks block (Figma 10167:15082).
  module ThanksBarComponentStyles
    ROOT = [
      'chapter-thanks-bar mx-auto flex w-full max-w-[1216px] flex-col items-center gap-3',
      'px-4 py-8 text-center'
    ].join(' ').freeze

    TITLE = 'text-lg/7 font-semibold text-fg md:text-xl/7'
    CREDIT = 'text-sm/5 text-fg-muted'
    STATUS = 'text-sm/5 text-fg-secondary'
    SUPPORT = 'text-sm/5 text-fg-muted'
    SUPPORT_LINK = 'font-medium text-fg-brand hover:text-brand-hover'
    GUEST = 'text-sm/5 text-fg-secondary'
    GUEST_LINK = 'font-semibold text-fg-brand hover:text-brand-hover'
    OWNER_COUNT = 'text-base/6 font-medium text-fg'

    PILL = [
      'inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm/5 font-medium',
      'transition-colors duration-200 focus:outline-none',
      'focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-main',
      'disabled:pointer-events-none disabled:opacity-50'
    ].join(' ').freeze

    PILL_IDLE = [
      PILL,
      'border-line bg-main text-fg hover:bg-surface focus-visible:ring-line-strong'
    ].join(' ').freeze

    PILL_THANKED = [
      PILL,
      'border-status-danger-subtle-border bg-status-danger-subtle-bg text-status-danger-subtle-fg',
      'hover:bg-status-danger-subtle-bg focus-visible:ring-status-danger-solid'
    ].join(' ').freeze

    HEART = 'size-4 shrink-0'
    HEART_THANKED = 'size-4 shrink-0 fill-current'
    DIVIDER = 'text-fg-muted'
  end
end
