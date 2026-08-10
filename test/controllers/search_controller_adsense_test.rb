# frozen_string_literal: true

require 'test_helper'

class SearchControllerAdsenseTest < ActionDispatch::IntegrationTest
  include SearchControllerTesting

  test 'index omits adsense slots outside development' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        get search_index_url, params: { search: ['test'] }
      end
    end

    assert_response :success
    assert_select '.adsense-collapse-safe', count: 0
  end

  test 'index renders adsense slot preview in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      with_stubbed_tag_counts do
        with_stubbed_search(Fiction, Publication, YoutubeVideo) do
          get search_index_url, params: { search: ['test'] }
        end
      end
    end

    assert_response :success
    assert_select '.adsense-collapse-safe #adsense-slot-search_index-sidebar.reader-ad-slot--preview',
                  count: 1
  end
end
