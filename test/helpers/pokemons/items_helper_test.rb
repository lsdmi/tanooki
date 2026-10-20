# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class ItemsHelperTest < ActionView::TestCase
    include ItemsHelper

    test 'item icons render decorative svg' do
      render html: pokemon_item_icon('protein') + pokemon_candy_icon + pokemon_bag_icon +
                   pokemon_item_icon('lure') + pokemon_item_icon('incense')

      assert_select 'svg[aria-hidden=true]', count: 5
    end

    test 'pokemon_missions_icon renders decorative scroll' do
      render html: pokemon_missions_icon

      assert_select 'svg[aria-hidden=true].size-3\\.5'
      assert_select 'svg path', count: MISSIONS_PATHS.size
    end

    test 'flavor copy is pokemon-styled ukrainian' do
      assert_includes pokemon_item_flavor('incense'), 'Дикі покемони'
      assert_equal 'Протеїн', pokemon_item_name('protein')
    end
  end
end
