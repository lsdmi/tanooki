# frozen_string_literal: true

require 'test_helper'

module Root
  class HeroBannerTest < ActiveSupport::TestCase
    setup do
      Rails.cache.clear
    end

    test 'uses the same banner for everyone during the day' do
      travel_to Time.zone.parse('2026-07-02 12:00') do
        first = HeroBanner.current
        second = HeroBanner.current

        assert_equal first[:key], second[:key]
        assert Rails.cache.exist?(HeroBanner.cache_key_for)
      end
    end

    test 'uses a separate cache bucket on the next day' do
      travel_to Time.zone.parse('2026-07-02 12:00') do
        Rails.cache.write(HeroBanner.cache_key_for, 'default')

        assert_equal 'default', HeroBanner.current[:key]
      end

      travel_to Time.zone.parse('2026-07-03 12:00') do
        Rails.cache.write(HeroBanner.cache_key_for, 'husky_1')

        assert_equal 'husky_1', HeroBanner.current[:key]
      end
    end

    test 'preview overrides the daily banner' do
      Rails.cache.write(HeroBanner.cache_key_for, 'husky_1')

      assert_equal 'default', HeroBanner.current(preview_key: 'default')[:key]
      assert_equal 'husky_1', HeroBanner.current(preview_key: 'husky_1')[:key]
    end

    test 'falls back to the daily banner when preview key is unknown' do
      Rails.cache.write(HeroBanner.cache_key_for, 'husky_1')

      assert_equal 'husky_1', HeroBanner.current(preview_key: 'missing')[:key]
    end

    test 'resolves mobile_wide path for default' do
      assert_equal 'banner/banner_mobile_wide.webp', HeroBanner.current(preview_key: 'default')[:mobile_wide]
    end

    test 'resolves mobile_wide path for husky_1' do
      assert_equal 'banner/banner_mobile_wide_husky_1.webp', HeroBanner.current(preview_key: 'husky_1')[:mobile_wide]
    end

    test 'resolves mobile_wide path for husky_2' do
      assert_equal 'banner/banner_mobile_wide_husky_2.webp', HeroBanner.current(preview_key: 'husky_2')[:mobile_wide]
    end

    test 'resolves mobile_wide path for mstv' do
      assert_equal 'banner/banner_mobile_wide_mstv.webp', HeroBanner.current(preview_key: 'mstv')[:mobile_wide]
    end

    test 'preview returns husky_2 assets' do
      banner = HeroBanner.current(preview_key: 'husky_2')

      assert_equal 'banner/banner_desktop_husky_2.webp', banner[:desktop]
      assert_equal 'banner/banner_mobile_tall_husky_2.webp', banner[:mobile]
    end

    test 'preview returns mstv assets' do
      banner = HeroBanner.current(preview_key: 'mstv')

      assert_equal 'banner/banner_desktop_mstv.webp', banner[:desktop]
      assert_equal 'banner/banner_mobile_tall_mstv.webp', banner[:mobile]
    end
  end
end
