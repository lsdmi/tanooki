# frozen_string_literal: true

module Library
  # Tailwind class strings for Library::EntryComponent (Figma «Library entry» 10167:15051).
  module EntryComponentStyles
    # Mobile: cover beside the text, ⋮ top-right, the button under the bar. From md: one line, button and ⋮ last.
    ROW = [
      'relative grid grid-cols-[3rem_minmax(0,1fr)_auto] gap-x-3 gap-y-3 rounded-xl border border-line bg-main p-3',
      'transition-colors hover:border-line-strong',
      'md:grid-cols-[3rem_minmax(0,1fr)_auto_auto] md:items-center md:gap-x-4'
    ].join(' ').freeze
    COVER_CELL = 'col-start-1 row-span-2 row-start-1 self-start md:row-span-1 md:self-center'
    COVER = 'aspect-[74/105] w-12 rounded-md object-cover shadow-sm'
    INFO_CELL = 'col-start-2 row-start-1 flex min-w-0 flex-col gap-1'
    # Stretched over the row, so a click anywhere but the button and ⋮ opens the fiction page.
    TITLE_LINK = 'line-clamp-2 text-sm/5 font-medium text-fg after:absolute after:inset-0 after:rounded-xl ' \
                 'focus:outline-none focus-visible:after:ring-2 focus-visible:after:ring-brand ' \
                 'md:line-clamp-1 md:text-base/6'
    META = 'text-xs/5 text-fg-secondary md:text-sm/5'
    BAR = 'mt-1 w-full max-w-60'
    ACTION_CELL = 'relative col-start-2 row-start-2 md:col-start-3 md:row-start-1'
    MENU_CELL = 'relative col-start-3 row-start-1 -mt-1 -mr-1 self-start md:col-start-4 md:m-0 md:self-center'
  end
end
