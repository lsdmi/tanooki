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

    test 'navbar_fragment_cacheable? is true for guests only' do
      guest = Object.new.extend(LayoutFragmentKeysHelper)
      guest.define_singleton_method(:current_user) { nil }

      signed_in = Object.new.extend(LayoutFragmentKeysHelper)
      signed_in.define_singleton_method(:current_user) { User.new(id: 1) }

      assert_predicate guest, :navbar_fragment_cacheable?
      assert_not signed_in.navbar_fragment_cacheable?
    end

    test 'navbar_fragment_cache_key is guest scoped' do
      helper = Object.new.extend(LayoutFragmentKeysHelper)
      helper.define_singleton_method(:current_user) { nil }
      helper.define_singleton_method(:cookies) { {} }

      assert_equal 'navbar/v2/guest', helper.navbar_fragment_cache_key.first
    end
  end
end
