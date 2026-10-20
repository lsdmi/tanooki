# frozen_string_literal: true

module Pokemons
  # Bag / candy icons for Studio. Path data lives in +config/pokemon_item_icons.yml+.
  module ItemsHelper
    ICON_STROKE = {
      stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round'
    }.freeze
    # Lucide «scroll-text» — daily missions strip affordance.
    MISSIONS_PATHS = [
      'M15 12h-5', 'M15 8h-5', 'M19 17V5a2 2 0 0 0-2-2H4',
      'M8 21h12a2 2 0 0 0 2-2v-1a1 1 0 0 0-1-1H11a1 1 0 0 0-1 1v1a2 2 0 1 1-4 0V5a2 2 0 1 0-4 0v2a1 1 0 0 0 1 1h3'
    ].freeze

    def self.icons
      @icons ||= YAML.safe_load_file(Rails.root.join('config/pokemon_item_icons.yml'))
    end

    def pokemon_item_name(key)
      t("pokemons.items.names.#{key}")
    end

    def pokemon_item_flavor(key)
      t("pokemons.items.flavor.#{key}")
    end

    def pokemon_item_icon(key, size: 'size-5')
      key = key.to_s
      fill = ItemsHelper.icons.fetch('fill')
      return fill_icon(fill.fetch(key), size) if fill.key?(key)

      paths = ItemsHelper.icons.fetch('stroke').fetch(key, ItemsHelper.icons.dig('stroke', 'protein'))
      stroke_icon_svg(paths, size)
    end

    def pokemon_candy_icon(size: 'size-3.5')
      fill_icon(ItemsHelper.icons.fetch('fill').fetch('candy'), size)
    end

    def pokemon_bag_icon(size: 'size-3.5')
      fill_icon(ItemsHelper.icons.fetch('fill').fetch('bag'), size)
    end

    def pokemon_missions_icon(size = 'size-3.5')
      stroke_icon_svg(MISSIONS_PATHS, size)
    end

    private

    def fill_icon(definition, size)
      tag.svg(safe_join(definition.fetch('paths').map { |d| tag.path(d: d, fill: 'currentColor') }),
              class: size, viewBox: definition.fetch('view_box'), aria: { hidden: true })
    end

    def stroke_icon_svg(paths, size)
      tag.svg(safe_join(paths.map { |d| tag.path(d: d) }),
              class: size, viewBox: '0 0 24 24', fill: 'none', aria: { hidden: true }, **ICON_STROKE)
    end
  end
end
