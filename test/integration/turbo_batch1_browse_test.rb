# frozen_string_literal: true

require 'test_helper'

class TurboBatch1BrowseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include SearchControllerTesting

  test 'library index browse links do not disable Turbo Drive' do
    sign_in users(:user_two)

    get library_url

    assert_response :success
    assert_no_match(/turbo:\s*false|data-turbo="false"/, response.body)
  end

  test 'search index browse links do not disable Turbo Drive' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        get search_index_url, params: { search: ['test'] }

        assert_response :success
        assert_no_match(/turbo:\s*false|data-turbo="false"/, response.body)
      end
    end
  end

  test 'search fiction tiles escape turbo frame for full-page visits' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        get search_index_url, params: { search: ['test'] }

        assert_response :success
        assert_select 'turbo-frame#fictions-section a[data-turbo-frame="_top"]'
      end
    end
  end
end
