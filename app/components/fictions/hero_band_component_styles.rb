# frozen_string_literal: true

module Fictions
  # Tailwind class strings for Fictions::HeroBandComponent (Figma «Hero band» 10088:10422).
  # The band is dark in both themes, so its text and base colors are raw on purpose.
  module HeroBandComponentStyles
    ROOT = 'token-raw relative z-20 isolate bg-zinc-950 text-white'
    # Cropped toward the top, as in Figma. The light blur only hides the upscaling; scale-105 hides its soft edges.
    BACKDROP_IMAGE = 'absolute inset-0 size-full scale-105 object-cover object-[50%_10%] blur-xs'
    # Two layers: the gradient keeps the bottom (buttons) darkest, the flat dim keeps the art behind the text.
    SCRIM = 'absolute inset-0 bg-linear-to-t from-overlay-scrim-85 via-overlay-scrim-60 to-overlay-scrim-40'
    DIM = 'absolute inset-0 bg-overlay-scrim-40'
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
    COVER_PLACEHOLDER = 'token-raw aspect-[74/105] w-full rounded-lg bg-zinc-800 md:rounded-xl'

    TAGS_CELL = 'col-start-2 row-start-1 flex flex-wrap items-center gap-2 self-start'
    AGE_TAG = 'token-raw inline-flex items-center gap-1 rounded-md bg-rose-600 px-2 py-1 text-sm/5 font-medium ' \
              'text-white'
    STATUS_TAG = 'token-raw inline-flex items-center rounded-md border border-slate-400 px-3 py-1 text-sm/5 ' \
                 'font-medium text-white'

    STATS_CELL = [
      'col-start-2 row-start-2 mt-3 flex flex-col gap-2 self-start',
      'md:row-start-3 md:mt-4 md:flex-row md:flex-wrap md:gap-x-5 md:gap-y-2'
    ].join(' ').freeze
    STAT = 'token-raw flex items-center gap-1 text-sm/5 font-medium text-slate-300'
    STAT_ICON = 'token-raw size-4 shrink-0 text-slate-300'
    RATING_ICON = 'size-4 shrink-0 text-amber-400'

    TITLE_CELL = 'col-span-2 row-start-3 mt-5 flex flex-col gap-2 md:col-span-1 md:col-start-2 md:row-start-2 md:mt-4'
    TITLE = 'text-2xl/8 font-bold text-balance text-white md:text-4xl/tight lg:text-5xl/14'
    ORIGINAL_TITLE = 'token-raw line-clamp-2 text-sm/5 text-slate-300 md:text-lg/7'

    CREDITS_CELL = [
      'token-raw col-span-2 row-start-4 mt-2 text-xs/5 text-slate-400',
      'md:col-span-1 md:col-start-2 md:mt-4 md:text-sm/5'
    ].join(' ').freeze
    CREDIT_LINK = 'token-raw text-slate-300 underline-offset-4 hover:text-white hover:underline'

    ACTIONS_CELL = 'col-span-2 row-start-5 mt-5 md:col-span-1 md:col-start-2 md:mt-4'
  end
end
