# frozen_string_literal: true

module Ui
  # Inline 24 px Lucide stroke icons by name. Decorative: hidden from assistive tech.
  module StrokeIconHelper
    STROKE_ICON_PATHS = {
      book_open: ['M12 7v14',
                  'M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13' \
                  'a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z'],
      bookmark: ['m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z'],
      chevron_down: ['m6 9 6 6 6-6'],
      eye: ['M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0',
            'M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0'],
      globe: ['M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0', 'M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20',
              'M2 12h20'],
      info: ['M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0', 'M12 16v-4', 'M12 8h.01'],
      list: ['M3 12h.01', 'M3 18h.01', 'M3 6h.01', 'M8 12h13', 'M8 18h13', 'M8 6h13'],
      pencil: ['M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 ' \
               '.623.622l4.353-1.32a2 2 0 0 0 .83-.497z',
               'm15 5 4 4'],
      plus: ['M5 12h14', 'M12 5v14'],
      sliders: ['M21 4h-7', 'M10 4H3', 'M21 12h-9', 'M8 12H3', 'M21 20h-5', 'M12 20H3',
                'M14 2v4', 'M8 10v4', 'M16 18v4'],
      star: ['M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 ' \
             '.294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428' \
             'a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879' \
             'L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z'],
      trash: ['M3 6h18', 'M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6', 'M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2']
    }.freeze

    def stroke_icon(name, classes = 'size-4 shrink-0')
      tag.svg(class: classes, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2,
              'stroke-linecap': 'round', 'stroke-linejoin': 'round', aria: { hidden: true }) do
        safe_join(STROKE_ICON_PATHS.fetch(name).map { |d| tag.path(d:) })
      end
    end
  end
end
