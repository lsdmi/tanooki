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
end
