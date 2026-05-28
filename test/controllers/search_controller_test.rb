# frozen_string_literal: true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    advertisements(:advertisement_one)
  end

  test 'should get index with search' do
    with_stubbed_search(Fiction, Publication, YoutubeVideo) do
      get search_index_url, params: { search: ['test'] }

      assert_response :success
    end
  end

  test 'should get index with fiction filter only' do
    with_stubbed_search(Fiction) do
      get search_index_url, params: { search: ['test'], filter: 'fiction' }

      assert_fiction_filter_search_response
    end
  end

  test 'should redirect to root without search' do
    get search_index_url

    assert_redirected_to root_path
  end

  test 'fiction search passes page and per_page to Searchkick' do
    captured = {}

    Fiction.stub :search, lambda { |*_args, **options|
      captured[:page] = options[:page]
      captured[:per_page] = options[:per_page]
      stubbed_search_results(Fiction.limit(options[:per_page] || 24), total_count: 100)
    } do
      get search_index_url, params: { search: ['test'], filter: 'fiction', page: 2 }
    end

    assert_response :success
    assert_equal 2, captured[:page]
    assert_equal 24, captured[:per_page]
  end

  test 'returns empty results when OpenSearch is unavailable' do
    Fiction.stub :search, lambda { |*_args, **_kwargs|
      raise Faraday::ConnectionFailed, 'Failed to open TCP connection'
    } do
      get search_index_url, params: { search: ['test'], filter: 'fiction' }
    end

    assert_response :success
    assert_empty assigns(:fictions)
    assert assigns(:search_unavailable)
  end

  private

  def with_stubbed_search(*models)
    if models.empty?
      yield
    else
      model = models.first
      model.stub(:search, stubbed_search_results(model.all)) do
        with_stubbed_search(*models[1..]) { yield }
      end
    end
  end

  def stubbed_search_results(records, total_count: nil)
    total_count ||= records.size
    results = records.to_a

    results.define_singleton_method(:total_count) { total_count }
    results.define_singleton_method(:includes) { |*_associations| self }
    results
  end

  def assert_fiction_filter_search_response
    assert_response :success
    assert_equal Fiction.all.to_a, assigns(:fictions).to_a
    assert_empty assigns(:results)
    assert_empty assigns(:videos)
    assert_not_nil assigns(:pagy_fictions)
  end
end
