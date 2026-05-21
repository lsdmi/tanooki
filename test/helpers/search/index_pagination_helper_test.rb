# frozen_string_literal: true

require 'test_helper'

module Search
  class IndexPaginationHelperTest < ActionView::TestCase
    include IndexPaginationHelper
    include Pagination::TurboNavHelper
    include Rails.application.routes.url_helpers

    setup do
      request.path = search_index_path
      controller.params = ActionController::Parameters.new
    end

    test 'search_index_pagy_custom_params returns only section when no filter or search' do
      assert_equal({ section: 'results' }, search_index_pagy_custom_params('results'))
    end

    test 'search_index_pagy_custom_params keeps allowed filter and search terms' do
      controller.params[:filter] = 'fiction'
      controller.params[:search] = %w[one two]

      assert_equal(
        { search: %w[one two], filter: 'fiction', section: 'videos' },
        search_index_pagy_custom_params('videos')
      )
    end

    test 'search_index_pagy_custom_params drops filter when not in allowlist' do
      controller.params[:filter] = 'not_a_real_filter'
      controller.params[:search] = ['x']

      assert_equal({ search: ['x'], section: 'results' }, search_index_pagy_custom_params('results'))
    end

    test 'search_index_pagy_nav_html returns pagy nav markup' do
      pagy = Pagy.new(count: 50, page: 1, items: 10)
      html = search_index_pagy_nav_html(pagy, frame_id: 'results-section', section: 'results')

      assert_includes html, 'pagy nav'
      assert_includes html, 'results-section'
    end
  end
end
