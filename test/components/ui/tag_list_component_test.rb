# frozen_string_literal: true

require 'test_helper'

module Ui
  class TagListComponentTest < ViewComponentTestCase
    test 'renders nothing when labels empty' do
      render_inline(TagListComponent.new(labels: []))

      assert_no_selector 'a, span'
    end

    test 'renders tags with href builder' do
      render_inline(
        TagListComponent.new(
          labels: %w[аніме fantasy],
          variant: :keyword,
          href_builder: ->(label) { "/search?q=#{label}" },
          current_label: 'аніме'
        )
      )

      assert_selector 'a', count: 2
      assert_selector 'a.bg-cyan-700', count: 1
      assert_selector 'a.border-gray-300', count: 1
    end

    test 'passes counts to tags' do
      render_inline(
        TagListComponent.new(
          labels: %w[аніме empty],
          counts: { 'аніме' => 12, 'empty' => 0 }
        )
      )

      assert_selector 'span', text: '12'
      assert_no_selector 'span', text: '0'
    end
  end
end
