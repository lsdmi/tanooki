# frozen_string_literal: true

require 'test_helper'

class SearchControllerIndexedTermsTest < ActionDispatch::IntegrationTest
  include SearchControllerTesting

  setup do
    ActionController::Base.cache_store.clear
  end

  test 'takes search terms sent as search[0]= from outside links' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        get '/search?search%5B0%5D=test'
      end
    end

    assert_response :success
    assert_select '[data-search-filter-url-value=?]', search_index_path(search: ['test'], filter: 'fiction')
  end

  test 'redirects home when search[0]= is blank' do
    get '/search?search%5B0%5D='

    assert_redirected_to root_path
  end
end
