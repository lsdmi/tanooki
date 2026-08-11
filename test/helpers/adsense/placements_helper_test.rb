# frozen_string_literal: true

require 'test_helper'

module Adsense
  class PlacementsHelperTest < ActionView::TestCase
    include PlacementsHelper

    test 'adsense_slot_live? requires allowed adsense and a configured slot id' do
      define_singleton_method(:adsense_allowed?) { true }

      assert adsense_slot_live?(:fiction_alphabetical)
      assert_equal Adsense::SLOTS[:fiction_alphabetical], adsense_slot_id(:fiction_alphabetical)
    end

    test 'browse page slots are live when adsense is allowed' do
      define_singleton_method(:adsense_allowed?) { true }

      %i[
        bookshelf youtube_video youtube_index translation_requests_sidebar
        translation_requests_top tales_index tales_show search_index
        fictions_index_top fictions_index_mid genres_show_top genres_show_mid
        fiction_show fiction_show_sidebar
      ].each do |placement|
        assert adsense_slot_live?(placement), "expected #{placement} to be live"
        assert_equal Adsense::SLOTS[placement], adsense_slot_id(placement)
      end
    end

    test 'home banner slots are live when adsense is allowed' do
      define_singleton_method(:adsense_allowed?) { true }

      Adsense::HOME_BANNER_PLACEMENTS.each_key do |placement|
        assert adsense_slot_live?(placement)
        assert_equal Adsense::SLOTS[placement], adsense_slot_id(placement)
      end
    end

    test 'adsense_home_banners_renderable? follows development preview rules' do
      define_singleton_method(:adsense_allowed?) { false }

      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        assert_predicate self, :adsense_home_banners_renderable?
      end

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        define_singleton_method(:adsense_allowed?) { true }

        assert_predicate self, :adsense_home_banners_renderable?
      end
    end

    test 'adsense_slot_live? is false when adsense is disabled' do
      define_singleton_method(:adsense_allowed?) { false }

      assert_not adsense_slot_live?(:chapter_reader_top)
    end

    test 'adsense_slot_renderable? is true in development without a live slot' do
      define_singleton_method(:adsense_allowed?) { false }

      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        assert adsense_slot_renderable?(:bookshelf)
        assert_predicate self, :adsense_slot_development_preview?
      end

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        define_singleton_method(:adsense_allowed?) { true }

        assert adsense_slot_renderable?(:bookshelf)
      end
    end

    test 'adsense_adblock_check? is true in development for preview slots' do
      define_singleton_method(:adsense_allowed?) { false }

      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        assert_predicate self, :adsense_adblock_check?
      end

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        define_singleton_method(:adsense_allowed?) { true }

        assert_predicate self, :adsense_adblock_check?
      end
    end

    test 'calendar_ad_slot_for rotates through CALENDAR_SLOTS' do
      define_singleton_method(:calendar_ad_slots) { %w[111 222 333] }

      rotated = Array.new(4) { |index| calendar_ad_slot_for(index) }

      assert_equal %w[111 222 333 111], rotated
    end

    test 'calendar_adsense_live? requires allowed adsense and configured calendar slots' do
      define_singleton_method(:adsense_allowed?) { true }

      assert_predicate self, :calendar_adsense_live?

      original = Adsense::CALENDAR_SLOTS
      Adsense.send(:remove_const, :CALENDAR_SLOTS)
      Adsense.const_set(:CALENDAR_SLOTS, [].freeze)

      assert_not calendar_adsense_live?
    ensure
      Adsense.send(:remove_const, :CALENDAR_SLOTS) if Adsense.const_defined?(:CALENDAR_SLOTS)
      Adsense.const_set(:CALENDAR_SLOTS, original)
    end

    test 'calendar_adsense_renderable? is true in development without live slots' do
      define_singleton_method(:adsense_allowed?) { false }

      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        assert_predicate self, :calendar_adsense_renderable?
      end
    end
  end
end
