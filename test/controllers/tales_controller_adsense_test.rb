# frozen_string_literal: true

require 'test_helper'

class TalesControllerAdsenseTest < ActionDispatch::IntegrationTest
  setup do
    @tale = publications(:tale_approved_one)
  end

  test 'index omits legacy banners outside development' do
    Search::TagCounts.stub(:call, {}) do
      get tales_url
    end

    assert_response :success
    assert_select '[id^="advertisement-banner-"]', count: 0
    assert_select '.adsense-collapse-safe', count: 0
  end

  test 'index renders adsense slot preview in development when tenth tile exists' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      Search::TagCounts.stub(:call, {}) do
        get tales_url
      end

      assert_response :success
      if assigns(:highlights).size >= 10
        assert_select '.adsense-collapse-safe #adsense-slot-tales_index-tile-10.reader-ad-slot--preview',
                      count: 1
      else
        assert_select '.adsense-collapse-safe', count: 0
      end
    end
  end

  test 'show omits legacy banners outside development' do
    Search::TagCounts.stub(:call, {}) do
      Publication.stub :search, Publication.all do
        get tale_url(@tale)
      end
    end

    assert_response :success
    assert_select '[id^="advertisement-banner-"]', count: 0
    assert_select '.adsense-collapse-safe', count: 0
  end

  test 'show renders adsense slot preview in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      Search::TagCounts.stub(:call, {}) do
        Publication.stub :search, Publication.all do
          get tale_url(@tale)
        end
      end
    end

    assert_response :success
    assert_select '.adsense-collapse-safe #adsense-slot-tales_show-inline.reader-ad-slot--preview',
                  count: 1
  end
end
