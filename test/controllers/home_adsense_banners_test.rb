# frozen_string_literal: true

require 'test_helper'

class HomeAdsenseBannersTest < ActionDispatch::IntegrationTest
  test 'homepage renders dual adsense banner row in development preview' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      Search::TagCounts.stub(:call, {}) { get root_url }

      assert_response :success
      assert_select 'section.home-banners[aria-label="Реклама"]', count: 1
      assert_select '.home-banner-slot--preview', count: 2
    end
  end

  test 'homepage loads adsense slot stylesheet in development preview' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      Search::TagCounts.stub(:call, {}) { get root_url }

      assert_select 'link[href*="adsense_slots"][data-turbo-track="reload"]'
    end
  end

  test 'homepage renders videos grid with two promo slots' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_response :success
    assert_select 'section.home-videos-ads', count: 1
    assert_select 'section.home-videos-ads .home-videos-ads__slot', count: 2
  end

  test 'homepage videos grid includes telegram and buymeacoffee promo banners' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select 'section.home-videos-ads .community-banner img[src*="baka-telegram-mockup"]',
                  count: 1
    assert_select 'section.home-videos-ads .buymeacoffee-banner a[href*="buymeacoffee.com"]',
                  count: 1
  end

  test 'homepage promo banners defer decoration backgrounds' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select 'section.home-videos-ads .community-banner [data-lazy-bg-url-value*="psyduck"]',
                  count: 1
    assert_select 'section.home-videos-ads .buymeacoffee-banner [data-lazy-bg-url-value*="modal-bg"]',
                  count: 1
    assert_select 'section.home-videos-ads [style*="background-image"]', count: 0
  end
end
