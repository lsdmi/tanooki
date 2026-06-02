# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::GenrePageTagComponent variants.
  module GenrePageTagComponentStyles
    RANK_FEATURED_CLASSES = [
      'absolute left-2 top-2 z-10 flex h-7 min-w-[1.75rem] items-center justify-center',
      'rounded-lg border border-slate-600/55 bg-slate-400/45 px-2 text-sm font-bold text-slate-950 shadow-sm',
      'backdrop-blur-[2px] pointer-events-none',
      'dark:border-slate-300/45 dark:bg-slate-900/55 dark:text-white'
    ].join(' ').freeze

    RANK_THUMB_CLASSES = [
      'absolute left-2 top-2 z-10 flex h-6 min-w-[1.5rem] items-center justify-center',
      'rounded-lg border border-slate-500/70 bg-white/55 px-1.5 text-xs font-bold text-slate-900 shadow-sm',
      'backdrop-blur-[2px] pointer-events-none',
      'dark:border-slate-400/50 dark:bg-slate-900/55 dark:text-white'
    ].join(' ').freeze

    STAT_VIEWS_CLASSES = [
      'inline-flex min-w-0 max-w-[58%] items-center gap-1 rounded-lg bg-black/40 px-2 py-0.5',
      'text-[10px] font-medium leading-none text-white backdrop-blur-[2px] ring-1 ring-white/15',
      'transition-opacity duration-300 group-hover:opacity-95',
      'dark:bg-black/50 dark:ring-white/20'
    ].join(' ').freeze

    STAT_RATING_CLASSES = [
      'inline-flex shrink-0 items-center gap-0.5 rounded-lg bg-black/40 px-2 py-0.5',
      'text-[10px] font-semibold text-amber-300 backdrop-blur-[2px] ring-1 ring-white/15',
      'transition-opacity duration-300 group-hover:opacity-95',
      'dark:bg-black/50 dark:text-amber-200 dark:ring-white/20'
    ].join(' ').freeze

    CHAPTERS_CLASSES = [
      'shrink-0 rounded-lg border border-slate-400/90 bg-slate-100 px-2 py-0.5',
      'text-[10px] font-medium tabular-nums text-slate-600',
      'dark:border-slate-500 dark:bg-slate-700/80 dark:text-slate-200'
    ].join(' ').freeze

    STATUS_CLASSES = [
      'min-w-0 truncate rounded-lg border border-slate-300/90 bg-slate-50 px-2 py-0.5',
      'text-[10px] font-medium text-slate-600',
      'dark:border-slate-500 dark:bg-slate-800/60 dark:text-slate-300'
    ].join(' ').freeze

    GENRE_CLASSES = [
      'inline-flex items-center rounded-lg border border-slate-300 bg-white px-3 py-1 text-xs font-medium text-slate-700',
      'transition-colors hover:border-slate-400 hover:bg-slate-50 hover:text-slate-900',
      'focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500 focus-visible:ring-offset-2',
      'focus-visible:ring-offset-white',
      'dark:border-slate-500/45 dark:bg-slate-800/85 dark:text-slate-200',
      'dark:hover:border-slate-400/55 dark:hover:bg-slate-700/90 dark:hover:text-white',
      'dark:focus-visible:ring-slate-400 dark:focus-visible:ring-offset-2 dark:focus-visible:ring-offset-[#0f252c]'
    ].join(' ').freeze

    ADULT_CLASSES = [
      'inline-flex items-center gap-1 rounded-lg border border-orange-700 bg-orange-600 px-3 py-1',
      'text-xs font-medium text-white transition-colors hover:bg-orange-700',
      'focus:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2',
      'focus-visible:ring-offset-white',
      'dark:border-orange-400/80 dark:bg-orange-600 dark:hover:bg-orange-700',
      'dark:focus-visible:ring-orange-400 dark:focus-visible:ring-offset-[#0f252c]'
    ].join(' ').freeze

    RANK_CLASSES = {
      featured: RANK_FEATURED_CLASSES,
      thumb: RANK_THUMB_CLASSES
    }.freeze

    VARIANT_CLASSES = {
      stat_views: STAT_VIEWS_CLASSES,
      stat_rating: STAT_RATING_CLASSES,
      chapters: CHAPTERS_CLASSES,
      status: STATUS_CLASSES,
      genre: GENRE_CLASSES,
      adult: ADULT_CLASSES
    }.freeze

    ADULT_ICON_CLASSES = 'h-3.5 w-3.5 shrink-0 text-white'.freeze

    ICON_CLASSES = {
      stat_views: 'h-3 w-3 shrink-0 text-white/90',
      stat_rating: 'h-3 w-3 text-amber-300 dark:text-amber-200'
    }.freeze
  end
end
