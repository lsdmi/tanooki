# frozen_string_literal: true

module Fictions
  # Tailwind class strings for Fictions::HeroBandComponent (layout: Figma «Hero band» 10088:10422).
  # The band follows the theme: the cover is washed out in the page background color, so text uses the fg tokens.
  module HeroBandComponentStyles
    # Below the sticky tabs (z-30) so the backdrop never covers them, but above them while a shelf or team menu is
    # open: the menu cannot escape this stacking context on its own.
    ROOT = 'relative z-20 isolate text-fg has-[[role=dialog]:not([hidden])]:z-40'
    # A fixed-height strip at the top, so long content runs past the art onto the plain page background.
    BACKDROP = 'absolute inset-x-0 top-0 h-[26rem] overflow-hidden'
    # Cropped toward the top. Very light blur only — enough to soften under text, not mash the art.
    # scale-105 hides the soft edges blur leaves. CSS background shares the cover card URL (one fetch).
    BACKDROP_IMAGE = 'absolute inset-0 size-full scale-105 bg-cover bg-[position:50%_10%] blur-[1px]'
    # Ends in the page's own `bg-surface`, so the art fades into the page with no edge.
    # Keep the wash light enough that the cover still reads through (was /75 — too milky on thumb).
    WASH = 'absolute inset-0 bg-linear-to-b from-surface/55 to-surface dark:from-surface/50'
    # Same width and gutters as the navbar (`shared/_navbar`), so the edges line up.
    CONTAINER = 'relative mx-auto flex max-w-screen-xl flex-col gap-5 px-4 pt-4 pb-6 ' \
                'md:gap-8 md:pt-10 md:pb-12 2xl:px-0'

    # Mobile: cover beside tags + stats, top-aligned (row 2 takes the cover's extra height), the rest full width below.
    # From md: cover in its own column, the rest stacked beside it in Figma order.
    GRID = [
      'grid grid-cols-[7.75rem_minmax(0,1fr)] grid-rows-[auto_1fr] gap-x-4',
      'md:grid-cols-[13rem_minmax(0,1fr)] md:grid-rows-[repeat(5,auto)_1fr] md:gap-x-10',
      'lg:grid-cols-[18.5rem_minmax(0,1fr)]'
    ].join(' ').freeze

    COVER_CELL = 'col-start-1 row-span-2 row-start-1 self-start md:row-span-6'
    COVER_IMAGE = 'aspect-[74/105] w-full rounded-lg object-cover shadow-2xl md:rounded-xl'
    COVER_PLACEHOLDER = 'aspect-[74/105] w-full rounded-lg bg-surface-strong md:rounded-xl'

    TAGS_CELL = 'col-start-2 row-start-1 flex flex-wrap items-center gap-2 self-start'
    # Desktop only: on phones the tags must stay one line, so the stats beside the cover end above its bottom edge.
    AGE_TAG = 'inline-flex items-center gap-1 rounded-md px-2 py-1 text-sm/5 font-medium text-white max-md:hidden'
    # Danger / warning hues, as on the site's other rating tags. Not the status tokens: their warning and dark-mode
    # shades are too light for white text.
    AGE_TAG_TONES = {
      'eighteen' => 'token-raw bg-rose-600',
      'sixteen' => 'bg-orange-700'
    }.freeze
    # An inset ring, not a border, so it is as tall as the age tag beside it.
    STATUS_TAG = 'inline-flex items-center rounded-md bg-card px-3 py-1 text-sm/5 font-medium text-fg ring-1 ' \
                 'ring-inset ring-line-strong dark:bg-fg/8 dark:ring-fg/15'
    LICENSED_TAG = 'inline-flex items-center gap-1 rounded-md bg-status-licensed-subtle-bg px-3 py-1 text-sm/5 ' \
                   'font-medium text-status-licensed-solid ring-1 ring-inset ring-status-licensed-subtle-border ' \
                   'dark:bg-status-licensed-on-media-bg dark:text-status-licensed-on-media-title ' \
                   'dark:ring-status-licensed-on-media-border'

    STATS_CELL = [
      'col-start-2 row-start-2 mt-3 flex flex-col gap-2 self-start',
      'md:row-start-3 md:mt-4 md:flex-row md:flex-wrap md:gap-x-5 md:gap-y-2'
    ].join(' ').freeze
    STAT = 'flex items-center gap-1 text-sm/5 font-medium text-fg'
    # One line beside the cover on phones: a stat too long for the column ends at its last whole word.
    STAT_TEXT = 'line-clamp-1 min-w-0'
    STAT_ICON = 'size-4 shrink-0 text-fg-muted'
    RATING_ICON = 'size-4 shrink-0 text-amber-500'

    TITLE_CELL = 'col-span-2 row-start-3 mt-5 flex flex-col gap-2 md:col-span-1 md:col-start-2 md:row-start-2 md:mt-4'
    TITLE = 'text-2xl/8 font-bold text-balance text-fg md:text-4xl/tight lg:text-5xl/14'
    ORIGINAL_TITLE = 'line-clamp-2 text-sm/5 text-fg-secondary md:text-lg/7'

    CREDITS_CELL = [
      'col-span-2 row-start-4 mt-2 text-xs/5 text-fg-secondary',
      'md:col-span-1 md:col-start-2 md:mt-4 md:text-sm/5'
    ].join(' ').freeze
    # Always underlined: PSI link-in-text-block fails when links match surrounding text by color only.
    CREDIT_LINK = 'text-fg underline underline-offset-4'

    ACTIONS_CELL = 'col-span-2 row-start-5 mt-5 md:col-span-1 md:col-start-2 md:mt-4'
  end
end
