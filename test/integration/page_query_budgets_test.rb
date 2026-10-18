# frozen_string_literal: true

require 'test_helper'

# SQL-count ceilings for guest key pages (docs/completed/PERFORMANCE_INITIATIVE.md Stream 3).
# Counts are cold (cache cleared): a regression that only hits an uncached fragment still fails.
# Budgets are local fixture numbers with headroom;
# production p95 is higher because of data size, not because these pages may grow unbounded here.
class PageQueryBudgetsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include QueryBudgetHelper
  include SearchControllerTesting

  # Cold query ceilings (fixture counts + ~25% headroom). Chapter show re-measured 2026-10-16
  # after lazy comments/TOC drawers (~12 queries cold).
  HOME_QUERIES = 70
  FICTIONS_INDEX_QUERIES = 80
  FICTION_SHOW_QUERIES = 50
  CHAPTER_SHOW_QUERIES = 15
  # Cold fixture count for filter=all is ~36 after skipping inactive OS sections; 45 ≈ +25% headroom.
  SEARCH_QUERIES = 45
  # Studio blogs list uses publications.excerpt only (~30 cold); 40 ≈ +25% headroom.
  STUDIO_BLOGS_QUERIES = 40

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

  test 'studio blogs tab stays within its SQL budget and loads no Action Text' do
    sign_in users(:user_one)
    Rails.cache.clear
    assert_list_page_query_budget(STUDIO_BLOGS_QUERIES) { get studio_index_url(tab: 'blogs') }
    assert_response :success
  end
end
