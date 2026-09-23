# frozen_string_literal: true

module Ui
  # Tailwind / class strings for Ui::AgeRatingNotice.
  module AgeRatingNoticeStyles
    EIGHTEEN_ROOT = [
      'adult-content-disclaimer relative overflow-hidden mb-4 rounded-2xl bg-[#ff4d4f] px-4 py-3',
      'text-white shadow-[0_1px_2px_rgb(0_0_0/0.06),0_4px_14px_rgb(220_38_38/0.28)]',
      'dark:bg-[#c42f31] dark:shadow-[0_1px_2px_rgb(0_0_0/0.22),0_4px_16px_rgb(0_0_0/0.38)]',
      'sm:mb-6 sm:px-5 sm:py-3.5'
    ].join(' ').freeze

    SIXTEEN_ROOT = [
      'relative mb-4 rounded-2xl border border-amber-800 bg-amber-100 px-4 py-3 text-amber-950',
      'dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-50',
      'sm:mb-6 sm:px-5 sm:py-3.5'
    ].join(' ').freeze

    EIGHTEEN_ICON_WRAP =
      'adult-content-disclaimer__icon flex h-11 w-11 shrink-0 items-center ' \
      'justify-center rounded-xl bg-white dark:bg-zinc-100'

    SIXTEEN_ICON_WRAP =
      'flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ' \
      'bg-amber-200 dark:bg-amber-900/80'

    EIGHTEEN_ICON = 'h-6 w-6 text-[#d93c3e] dark:text-[#b83234]'
    SIXTEEN_ICON = 'h-6 w-6 text-amber-800 dark:text-amber-200'

    EIGHTEEN_DESCRIPTION = 'mt-0.5 text-xs leading-relaxed text-white/95 sm:text-sm'
    SIXTEEN_DESCRIPTION =
      'mt-0.5 text-xs leading-relaxed text-amber-900/90 dark:text-amber-100/90 sm:text-sm'

    EIGHTEEN_DISMISS = [
      'adult-content-disclaimer__dismiss w-full shrink-0 rounded-lg bg-white px-5 py-2 text-sm font-bold',
      'text-stone-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-white',
      'focus-visible:ring-offset-2 focus-visible:ring-offset-[#ff4d4f] dark:bg-zinc-100',
      'dark:text-stone-900 dark:hover:bg-white dark:focus-visible:ring-offset-[#c42f31]',
      'sm:w-auto sm:self-center'
    ].join(' ').freeze

    SIXTEEN_DISMISS = [
      'w-full shrink-0 rounded-lg border border-amber-800 bg-white px-5 py-2 text-sm font-bold',
      'text-amber-950 hover:bg-amber-50 focus:outline-none focus-visible:ring-2',
      'focus-visible:ring-amber-700 focus-visible:ring-offset-2 dark:border-amber-400',
      'dark:bg-amber-900/40 dark:text-amber-50 dark:hover:bg-amber-900/70',
      'sm:w-auto sm:self-center'
    ].join(' ').freeze
  end
end
