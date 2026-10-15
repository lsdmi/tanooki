# frozen_string_literal: true

require 'test_helper'

class SearchControllerFilterTest < ActionDispatch::IntegrationTest
  include SearchControllerTesting

  setup do
    ActionController::Base.cache_store.clear
  end

  test 'fiction filter does not call OpenSearch for blogs or videos' do
    publication_called = false
    video_called = false

    with_stubbed_tag_counts do
      Fiction.stub(:search, stubbed_search_results(Fiction.all)) do
        Publication.stub(:search, lambda { |*|
          publication_called = true
          stubbed_search_results(Publication.none)
        }) do
          YoutubeVideo.stub(:search, lambda { |*|
            video_called = true
            stubbed_search_results(YoutubeVideo.none)
          }) do
            get search_index_url, params: { search: ['test'], filter: 'fiction' }
          end
        end
      end
    end

    assert_response :success
    assert_not publication_called
    assert_not video_called
  end
end
