# frozen_string_literal: true

require 'test_helper'

module Layout
  class LazyBackgroundHelperTest < ActionView::TestCase
    include LazyBackgroundHelper

    test 'decoration_small_filename inserts sm before the extension' do
      assert_equal 'writer-sm.webp', decoration_small_filename('writer.webp')
      assert_equal 'psyduck_background-sm.webp', decoration_small_filename('psyduck_background.webp')
    end

    test 'lazy_decoration_background wires controller and observe flag' do
      attrs = lazy_decoration_background('writer.webp', html_class: 'home-tales')

      assert_equal 'home-tales', attrs[:class]
      assert_equal 'lazy-bg', attrs[:data][:controller]
      assert attrs[:data][:lazy_bg_observe_value]
    end

    test 'lazy_decoration_background prefers a mobile variant when present' do
      attrs = lazy_decoration_background('writer.webp', html_class: 'home-tales')

      assert_includes attrs[:data][:lazy_bg_url_value], 'writer'
      assert_includes attrs[:data][:lazy_bg_small_url_value], 'writer-sm'
    end

    test 'lazy_decoration_background omits missing mobile variants' do
      attrs = lazy_decoration_background('fiction-genre-writings-promo.webp', html_class: 'promo')

      assert_includes attrs[:data][:lazy_bg_url_value], 'fiction-genre-writings-promo'
      assert_nil attrs[:data][:lazy_bg_small_url_value]
    end

    test 'lazy_decoration_background forwards extra html attributes' do
      attrs = lazy_decoration_background('writer.webp', html_class: 'x', aria: { hidden: true })

      assert_equal({ hidden: true }, attrs[:aria])
    end
  end
end
