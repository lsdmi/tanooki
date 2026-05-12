# frozen_string_literal: true

require 'test_helper'

module Studio
  class TabCatalogTest < ActiveSupport::TestCase
    test 'normalize_tab_id falls back to blogs for unknown ids' do
      assert_equal 'blogs', TabCatalog.normalize_tab_id('not-a-tab')
    end

    test 'partial_for maps known tab ids to partial paths' do
      assert_equal 'studio/tabs/pokemons', TabCatalog.partial_for('pokemons')
      assert_equal 'studio/tabs/blogs', TabCatalog.partial_for('nope')
    end
  end
end
