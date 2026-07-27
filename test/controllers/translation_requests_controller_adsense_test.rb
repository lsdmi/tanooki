# frozen_string_literal: true

require 'test_helper'

class TranslationRequestsControllerAdsenseTest < ActionDispatch::IntegrationTest
  test 'index omits legacy banners outside development' do
    get translation_requests_url

    assert_response :success
    assert_select '[id^="advertisement-banner-"]', count: 0
    assert_select '.adsense-collapse-safe', count: 0
  end

  test 'index renders adsense slot previews in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get translation_requests_url

      assert_response :success
      assert_select '.adsense-collapse-safe #adsense-slot-translation_requests_sidebar-sidebar.reader-ad-slot--preview',
                    count: 1
      assert_select '.adsense-collapse-safe #adsense-slot-translation_requests_top-top.reader-ad-slot--preview',
                    count: 1
    end
  end
end
