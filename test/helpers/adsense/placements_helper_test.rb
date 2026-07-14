# frozen_string_literal: true

require 'test_helper'

module Adsense
  class PlacementsHelperTest < ActionView::TestCase
    include PlacementsHelper

    test 'adsense_slot_live? requires allowed adsense and a configured slot id' do
      define_singleton_method(:adsense_allowed?) { true }

      assert_not adsense_slot_live?(:fiction_alphabetical)
      assert_nil adsense_slot_id(:fiction_alphabetical)
    end

    test 'bookshelf slot is not live without env slot id' do
      define_singleton_method(:adsense_allowed?) { true }

      assert_not adsense_slot_live?(:bookshelf)
      assert_nil adsense_slot_id(:bookshelf)
    end

    test 'home banner left slot is not live without env slot id' do
      define_singleton_method(:adsense_allowed?) { true }

      assert_not adsense_slot_live?(:home_banner_left)
      assert_nil adsense_slot_id(:home_banner_left)
    end

    test 'home banner right slot is not live without env slot id' do
      define_singleton_method(:adsense_allowed?) { true }

      assert_not adsense_slot_live?(:home_banner_right)
      assert_nil adsense_slot_id(:home_banner_right)
    end

    test 'adsense_home_banners_renderable? is true in development without live slots' do
      define_singleton_method(:adsense_allowed?) { false }

      if Rails.env.development?
        assert_predicate self, :adsense_home_banners_renderable?
      else
        assert_not adsense_home_banners_renderable?
      end
    end

    test 'adsense_slot_live? is false when adsense is disabled' do
      define_singleton_method(:adsense_allowed?) { false }

      assert_not adsense_slot_live?(:chapter_reader_top)
    end

    test 'adsense_slot_renderable? is true in development without a live slot' do
      define_singleton_method(:adsense_allowed?) { false }

      if Rails.env.development?
        assert adsense_slot_renderable?(:bookshelf)
        assert_predicate self, :adsense_slot_development_preview?
      else
        assert_not adsense_slot_renderable?(:bookshelf)
      end
    end

    test 'adsense_adblock_check? is true in development for preview slots' do
      if Rails.env.development?
        assert_predicate self, :adsense_adblock_check?
      else
        define_singleton_method(:adsense_allowed?) { false }

        assert_not adsense_adblock_check?
      end
    end
  end
end
