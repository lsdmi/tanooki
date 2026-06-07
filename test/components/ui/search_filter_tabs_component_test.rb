# frozen_string_literal: true

require 'test_helper'

module Ui
  class SearchFilterTabsComponentTest < ViewComponentTestCase
    test 'renders selected tab as filter variant and others as keyword' do
      render_inline(
        SearchFilterTabsComponent.new(
          current_filter: 'fiction',
          search: ['українською'],
          pagy_fictions: pagy_with_count(1),
          pagy_results: pagy_with_count(5),
          pagy_videos: pagy_with_count(2)
        )
      )

      assert_selector 'button.border-cyan-800.bg-cyan-700', text: /Ранобе/
      assert_selector 'button.border-cyan-800 span', text: '1'
      assert_selector 'button.border-gray-300.bg-white', text: /Усе/
    end

    test 'renders all tab count from section pagy totals' do
      render_inline(
        SearchFilterTabsComponent.new(
          current_filter: 'fiction',
          search: ['українською'],
          pagy_fictions: pagy_with_count(1),
          pagy_results: pagy_with_count(5),
          pagy_videos: pagy_with_count(2)
        )
      )

      assert_selector 'button.border-gray-300 span', text: '8'
    end

    test 'all tab count sums section pagy counts' do
      render_inline(
        SearchFilterTabsComponent.new(
          current_filter: nil,
          search: ['test'],
          pagy_fictions: pagy_with_count(10),
          pagy_results: pagy_with_count(7),
          pagy_videos: pagy_with_count(3)
        )
      )

      assert_selector 'button.border-cyan-800 span', text: '20'
    end

    private

    def pagy_with_count(count)
      Pagy.new(count: count, page: 1, limit: 12)
    end
  end
end
