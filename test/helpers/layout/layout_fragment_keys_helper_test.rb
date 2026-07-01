# frozen_string_literal: true

require 'test_helper'

module Layout
  class LayoutFragmentKeysHelperTest < ActionView::TestCase
    include LayoutFragmentKeysHelper

    test 'advertisement_banner_ready? rejects ads without attachments' do
      advertisement = Advertisement.new(resource: 'https://example.com')

      assert_not advertisement_banner_ready?(advertisement)
    end

    test 'advertisement_cover_label falls back when cover is missing' do
      advertisement = Advertisement.new

      assert_equal 'Реклама', advertisement_cover_label(advertisement)
    end

    test 'navbar_fragment_cache_key uses shared namespace' do
      define_singleton_method(:cookies) { {} }

      assert_equal 'navbar/v3/shared', navbar_fragment_cache_key(:brand).first
    end

    test 'navbar_fragment_cache_key includes section name' do
      define_singleton_method(:cookies) { {} }

      assert_equal 'brand', navbar_fragment_cache_key(:brand).second
      assert_equal 'nav_links', navbar_fragment_cache_key(:nav_links).second
    end
  end
end
