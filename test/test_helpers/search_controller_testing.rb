# frozen_string_literal: true

module SearchControllerTesting
  def with_stubbed_tag_counts(&)
    Search::TagCounts.stub(:call, {}, &)
  end

  def with_stubbed_search(*models, &)
    return yield if models.empty?

    model = models.first
    model.stub(:search, stubbed_search_results(model.all)) do
      with_stubbed_search(*models[1..], &)
    end
  end

  def stubbed_search_results(records, total_count: nil)
    total_count ||= records.size
    results = records.to_a

    results.define_singleton_method(:total_count) { total_count }
    results.define_singleton_method(:includes) { |*_associations| self }
    results
  end

  def with_stubbed_search_counts(fiction:, publication:, video:, &)
    Fiction.stub(:search, stubbed_search_results(Fiction.all, total_count: fiction)) do
      Publication.stub(:search, stubbed_search_results(Publication.all, total_count: publication)) do
        YoutubeVideo.stub(:search, stubbed_search_results(YoutubeVideo.all, total_count: video), &)
      end
    end
  end

  def with_opensearch_unavailable(&)
    error = ->(*) { raise Faraday::ConnectionFailed, 'Failed to open TCP connection' }

    Fiction.stub(:search, error) do
      Publication.stub(:search, error) do
        YoutubeVideo.stub(:search, error, &)
      end
    end
  end

  def assert_fiction_filter_search_response
    assert_response :success
    assert_equal Fiction.all.to_a, assigns(:fictions).to_a
    assert_empty assigns(:results)
  end

  def assert_fiction_filter_pagy_assigns
    assert_empty assigns(:videos)
    assert_not_nil assigns(:pagy_fictions)
    assert_not_nil assigns(:pagy_results)
    assert_not_nil assigns(:pagy_videos)
  end
end
