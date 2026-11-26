# frozen_string_literal: true

require 'test_helper'

module Fictions
  module Reviews
    class FilterComponentTest < ViewComponentTestCase
      setup do
        @fiction = fictions(:two)
      end

      test 'a fiction without reviews shows no filter' do
        @fiction.update!(reviews_count: 0)

        render_inline(FilterComponent.new(fiction: @fiction, order: :desc, reviews_only: false))

        assert_predicate rendered_content.strip, :empty?
      end

      test 'offers all comments and the reviews with their count' do
        @fiction.update!(reviews_count: 3)

        render_inline(FilterComponent.new(fiction: @fiction, order: :desc, reviews_only: false))

        assert_selector 'a', text: 'Усі', count: 1
        assert_selector %(a[href="/fictions/#{@fiction.to_param}/comments?order=desc"]), text: 'Усі'
        assert_selector %(a[href="/fictions/#{@fiction.to_param}/comments?filter=reviews&order=desc"]),
                        text: 'Відгуки (3)'
      end

      test 'marks the active filter for assistive tech' do
        @fiction.update!(reviews_count: 3)

        render_inline(FilterComponent.new(fiction: @fiction, order: :asc, reviews_only: true))

        assert_selector 'a[aria-current="page"]', text: 'Відгуки (3)'
        assert_no_selector 'a[aria-current="page"]', text: 'Усі'
      end

      test 'keeps the chosen order in both links' do
        @fiction.update!(reviews_count: 1)

        render_inline(FilterComponent.new(fiction: @fiction, order: :asc, reviews_only: false))

        assert_selector %(a[href="/fictions/#{@fiction.to_param}/comments?order=asc"])
        assert_selector %(a[href="/fictions/#{@fiction.to_param}/comments?filter=reviews&order=asc"])
      end
    end
  end
end
