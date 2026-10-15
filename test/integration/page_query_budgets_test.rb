# frozen_string_literal: true

require 'test_helper'

# SQL-count ceilings for guest key pages (PERFORMANCE_INITIATIVE Stream 3). Counts are cold (cache cleared):
# a regression that only hits an uncached fragment still fails. Budgets are local fixture numbers with headroom;
# production p95 is higher because of data size, not because these pages may grow unbounded here.
class PageQueryBudgetsTest < ActionDispatch::IntegrationTest
  include QueryBudgetHelper
  include SearchControllerTesting

  # Cold query ceilings (measured 2026-10-15 on fixtures, then +~25% headroom).
  HOME_QUERIES = 70
  FICTIONS_INDEX_QUERIES = 80
  FICTION_SHOW_QUERIES = 50
  CHAPTER_SHOW_QUERIES = 20
  SEARCH_QUERIES = 50

  setup do
    @fiction = fictions(:one)
    @chapter = chapters(:one)
  end

  test 'homepage stays within its SQL budget and loads no chapter bodies' do
    with_stubbed_tag_counts do
      Rails.cache.clear
      assert_list_page_query_budget(HOME_QUERIES) { get root_url }
      assert_response :success
    end
  end

  test 'fictions index stays within its SQL budget and loads no chapter bodies' do
    Rails.cache.clear
    assert_list_page_query_budget(FICTIONS_INDEX_QUERIES) { get fictions_url }
    assert_response :success
  end

  test 'fiction show stays within its SQL budget' do
    Rails.cache.clear
    assert_queries_at_most(FICTION_SHOW_QUERIES) { get fiction_url(@fiction) }
    assert_response :success
  end

  test 'chapter show stays within its SQL budget' do
    Rails.cache.clear
    assert_queries_at_most(CHAPTER_SHOW_QUERIES) { get chapter_url(@chapter) }
    assert_response :success
  end

  test 'search stays within its SQL budget and loads no chapter bodies' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        Rails.cache.clear
        assert_list_page_query_budget(SEARCH_QUERIES) { get search_index_url, params: { search: ['test'] } }
        assert_response :success
      end
    end
  end
end
