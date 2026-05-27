# frozen_string_literal: true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    advertisements(:advertisement_one)
  end

  test 'should get index with search' do
    Publication.stub :search, Publication.all do
      Fiction.stub :search, Fiction.all do
        YoutubeVideo.stub :search, YoutubeVideo.all do
          get search_index_url, params: { search: ['test'] }

          assert_response :success
        end
      end
    end
  end

  test 'should get index with fiction filter only' do
    Fiction.stub :search, Fiction.all do
      get search_index_url, params: { search: ['test'], filter: 'fiction' }

      assert_fiction_filter_search_response
    end
  end

  test 'should redirect to root without search' do
    get search_index_url

    assert_redirected_to root_path
  end

  private

  def assert_fiction_filter_search_response
    assert_response :success
    assert_equal Fiction.all.to_a, assigns(:fictions).to_a
    assert_empty assigns(:results)
    assert_empty assigns(:videos)
    assert_not_nil assigns(:pagy_fictions)
  end
end
