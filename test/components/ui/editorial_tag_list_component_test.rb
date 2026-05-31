# frozen_string_literal: true

require 'test_helper'

module Ui
  class EditorialTagListComponentTest < ViewComponentTestCase
    test 'renders nothing when kinds empty' do
      render_inline(EditorialTagListComponent.new(kinds: []))

      assert_no_selector 'span'
    end

    test 'caps tags at hero max' do
      result = render_inline(EditorialTagListComponent.new(kinds: %i[adult novelty popular update]))

      assert_equal(['18+', 'Новинка'], result.css('span').map { |node| node.text.squish })
    end

    test 'passes label overrides' do
      render_inline(
        EditorialTagListComponent.new(
          kinds: [:popular],
          labels: { popular: 'Рекомендовано' }
        )
      )

      assert_text 'Рекомендовано'
    end
  end
end
