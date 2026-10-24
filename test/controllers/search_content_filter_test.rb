# frozen_string_literal: true

require 'test_helper'

class SearchContentFilterTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include SearchControllerTesting

  test 'open fiction search does not add a content filter' do
    captured = capture_fiction_search { get search_index_url, params: { search: ['test'], filter: 'fiction' } }

    assert_nil captured[:where]
    assert_not_includes response.body, I18n.t('content_filters.some_hidden')
  end

  test 'fiction search merges the account filter and paginates the filtered total' do
    sign_in users(:user_one)
    captured = capture_fiction_search(total_count: 2) do
      get search_index_url, params: { search: ['test'], filter: 'fiction' }
    end

    assert_equal({ content_rating: { lte: 16 } }, captured[:where])
    assert_equal 2, assigns(:pagy_fictions).count
    assert_includes response.body, I18n.t('content_filters.some_hidden')
  end

  test 'publication search ignores the content filter' do
    sign_in users(:user_one)
    captured = {}

    with_stubbed_tag_counts do
      Fiction.stub(:search, stubbed_search_results(Fiction.none)) do
        YoutubeVideo.stub(:search, stubbed_search_results(YoutubeVideo.none)) do
          Publication.stub(:search, lambda { |*_args, **options|
            captured[:where] = options[:where]
            stubbed_search_results(Publication.none)
          }) { get search_index_url, params: { search: ['test'], filter: 'blog' } }
        end
      end
    end

    assert_nil captured[:where]
  end

  private

  def capture_fiction_search(total_count: 1, &)
    captured = {}
    with_stubbed_tag_counts do
      YoutubeVideo.stub(:search, stubbed_search_results(YoutubeVideo.none)) do
        Publication.stub(:search, stubbed_search_results(Publication.none)) do
          Fiction.stub(:search, fiction_search_stub(captured, total_count), &)
        end
      end
    end
    captured
  end

  def fiction_search_stub(captured, total_count)
    lambda do |*_args, **options|
      captured[:where] = options[:where]
      stubbed_search_results(Fiction.limit(1), total_count:)
    end
  end
end
