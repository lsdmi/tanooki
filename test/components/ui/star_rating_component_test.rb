# frozen_string_literal: true

require 'test_helper'

module Ui
  class StarRatingComponentTest < ViewComponentTestCase
    test 'renders five full stars for a perfect rating' do
      render_inline(StarRatingComponent.new(rating: 5))

      assert_selector 'svg.text-yellow-400.fill-current', count: 5
    end

    test 'renders half star for a 4.5 rating' do
      render_inline(StarRatingComponent.new(rating: 4.5))

      assert_selector 'svg.text-yellow-400.fill-current', count: 5
      assert_selector 'div.relative', count: 1
    end

    test 'renders summary with formatted rating and count' do
      render_inline(StarRatingComponent.new(rating: 4.5, rating_count: 12, show_summary: true))

      assert_selector 'p.anime-text.text-stone-100', text: /4[,.]5/
      assert_text 'Рейтинг (12)'
    end

    test 'renders empty summary when rating is zero' do
      render_inline(StarRatingComponent.new(rating: 0, show_summary: true))

      assert_selector 'p.anime-text.text-stone-400', text: '—'
      assert_text 'Рейтинг'
      assert_no_text 'Рейтинг ('
    end
  end
end
