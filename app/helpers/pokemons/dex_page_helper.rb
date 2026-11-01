# frozen_string_literal: true

module Pokemons
  # Chip styles for the species Pokédex type filter.
  module DexPageHelper
    # Lucide «layout-grid» — clear “all types” chip (fits size-7; text «Усі» overflowed).
    DEX_ALL_CELLS = [[3, 3], [14, 3], [14, 14], [3, 14]].freeze

    def dex_type_chip_classes(selected)
      base = 'inline-flex size-7 items-center justify-center rounded-md text-fg-subtle ' \
             'transition-colors hover:text-fg focus:outline-none ' \
             'focus-visible:ring-2 focus-visible:ring-line-strong'
      selected ? "#{base} bg-brand-subtle text-fg" : base
    end

    def pokemon_dex_all_icon(size = 'size-3.5')
      cells = DEX_ALL_CELLS.map { |x, y| tag.rect(width: 7, height: 7, x:, y:, rx: 1) }
      tag.svg(safe_join(cells),
              class: size, viewBox: '0 0 24 24', fill: 'none', aria: { hidden: true },
              stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round')
    end
  end
end
