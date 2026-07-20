# frozen_string_literal: true

require 'test_helper'

class HomeAdsenseBannersTest < ActionDispatch::IntegrationTest
  test 'homepage renders dual adsense banner row in development preview' do
    skip 'Homepage AdSense previews require Rails.env.development?' unless Rails.env.development?

    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_response :success
    assert_select 'section.home-banners[aria-label="Реклама"]', count: 1
    assert_select '.home-banner-slot--preview', count: 2
  end

  test 'homepage renders videos grid with four slots' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_response :success
    assert_select 'section.home-videos-ads', count: 1
    assert_select 'section.home-videos-ads .home-videos-ads__slot', count: 4
  end

  test 'homepage videos grid includes telegram and buymeacoffee promo banners' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select 'section.home-videos-ads .community-banner img[src*="baka-telegram-mockup"]',
                  count: 1
    assert_select 'section.home-videos-ads .buymeacoffee-banner a[href*="buymeacoffee.com"]',
                  count: 1
  end

  test 'homepage videos grid shows two adsense previews in development' do
    skip 'Videos grid AdSense previews require Rails.env.development?' unless Rails.env.development?

    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_response :success
    assert_select 'section.home-videos-ads .home-banner-slot--preview', count: 2
  end
end
