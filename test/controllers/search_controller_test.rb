# frozen_string_literal: true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  include SearchControllerTesting

  setup do
    advertisements(:advertisement_one)
    ActionController::Base.cache_store.clear
  end

  test 'should get index with search' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        get search_index_url, params: { search: ['test'] }

        assert_response :success
      end
    end
  end

  test 'should get index with fiction filter only' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        get search_index_url, params: { search: ['test'], filter: 'fiction' }

        assert_fiction_filter_search_response
        assert_fiction_filter_pagy_assigns
      end
    end
  end

  test 'should redirect to root without search' do
    get search_index_url

    assert_redirected_to root_path
  end

  test 'rate limits search requests per ip' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        30.times do
          get search_index_url, params: { search: ['test'] }, env: { 'REMOTE_ADDR' => '203.0.113.13' }

          assert_response :success
        end

        get search_index_url, params: { search: ['test'] }, env: { 'REMOTE_ADDR' => '203.0.113.13' }

        assert_response :too_many_requests
      end
    end
  end

  test 'fiction search passes page and per_page to Searchkick' do
    captured = {}

    with_stubbed_tag_counts do
      with_stubbed_search(Publication, YoutubeVideo) do
        Fiction.stub :search, lambda { |*_args, **options|
          captured[:page] = options[:page]
          captured[:per_page] = options[:per_page]
          stubbed_search_results(Fiction.limit(options[:per_page] || 24), total_count: 100)
        } do
          get search_index_url, params: { search: ['test'], filter: 'fiction', page: 2 }
        end
      end
    end

    assert_response :success
    assert_equal 2, captured[:page]
    assert_equal 24, captured[:per_page]
  end

  test 'returns empty results when OpenSearch is unavailable' do
    with_stubbed_tag_counts do
      with_opensearch_unavailable do
        get search_index_url, params: { search: ['test'], filter: 'fiction' }
      end
    end

    assert_response :success
    assert_empty assigns(:fictions)
    assert assigns(:search_unavailable)
  end

  test 'filter tabs use pagy counts matching section totals' do
    with_stubbed_tag_counts do
      with_stubbed_search_counts(fiction: 10, publication: 7, video: 3) do
        get search_index_url, params: { search: ['test'] }
      end
    end

    assert_response :success
    assert_equal(
      { fiction: 10, publication: 7, video: 3 },
      {
        fiction: assigns(:pagy_fictions).count,
        publication: assigns(:pagy_results).count,
        video: assigns(:pagy_videos).count
      }
    )
  end
end
