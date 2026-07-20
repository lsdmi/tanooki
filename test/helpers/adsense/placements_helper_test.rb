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

    test 'home banner slots are not live without env slot ids' do
      define_singleton_method(:adsense_allowed?) { true }

      Adsense::HOME_BANNER_PLACEMENTS.each_key do |placement|
        assert_not adsense_slot_live?(placement)
        assert_nil adsense_slot_id(placement)
      end
    end

    test 'adsense_home_banners_renderable? follows development preview rules' do
      define_singleton_method(:adsense_allowed?) { false }

      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        assert_predicate self, :adsense_home_banners_renderable?
      end

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        assert_not adsense_home_banners_renderable?
      end
    end

    test 'adsense_home_videos_grid_renderable? follows development preview rules' do
      define_singleton_method(:adsense_allowed?) { false }

      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        assert_predicate self, :adsense_home_videos_grid_renderable?
      end

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        assert_not adsense_home_videos_grid_renderable?
      end
    end

    test 'home_videos_grid_cells include community and buymeacoffee promo cards' do
      promo_cells = adsense_home_videos_grid_cells.last(2).map { |cell| cell.slice(:kind, :promo) }

      assert_equal [
        { kind: :promo, promo: :community },
        { kind: :promo, promo: :buymeacoffee }
      ], promo_cells
    end

    test 'home_videos_grid_ad_placements only include top row ad slots' do
      assert_equal %i[home_videos_grid_top_left home_videos_grid_top_right],
                   adsense_home_videos_grid_ad_placements.keys.sort
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
        assert_not adsense_slot_renderable?(:bookshelf)
      end
    end

    test 'adsense_adblock_check? is true in development for preview slots' do
      define_singleton_method(:adsense_allowed?) { false }

      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        assert_predicate self, :adsense_adblock_check?
      end

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        assert_not adsense_adblock_check?
      end
    end
  end
end
