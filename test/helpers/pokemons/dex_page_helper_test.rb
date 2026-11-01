# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DexPageHelperTest < ActionView::TestCase
    test 'dex type chip marks the selected filter without a ring' do
      selected = dex_type_chip_classes(true)

      assert_includes selected, 'bg-brand-subtle'
      assert_not_includes selected, 'ring-brand'
      assert_not_includes dex_type_chip_classes(false), 'bg-brand-subtle'
    end

    test 'pokemon_dex_all_icon renders a four-cell grid' do
      render html: pokemon_dex_all_icon

      assert_select 'svg[aria-hidden=true] rect', count: DEX_ALL_CELLS.size
    end
  end
end
