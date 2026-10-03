# frozen_string_literal: true

require 'test_helper'

module Fictions
  class RatingCardComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
      @fiction.fiction_ratings.delete_all
    end

    test 'a signed-in reader rates with star buttons posting to the fiction ratings' do
      render_inline(RatingCardComponent.new(fiction: @fiction, user: users(:user_one)))

      url = "/fictions/#{@fiction.id}/fiction_ratings"

      assert_selector "section[data-controller='rating'][data-rating-url-value='#{url}']"
      assert_selector 'button[data-rating-target="star"][data-action="rating#rate"]', count: 5
    end

    test 'the stars show the reader their own rating' do
      user = users(:user_one)
      FictionRating.create!(fiction: @fiction, user:, rating: 3)
      FictionRating.create!(fiction: @fiction, user: users(:user_two), rating: 5)

      render_inline(RatingCardComponent.new(fiction: @fiction.reload, user:))

      assert_selector 'button .fill-amber-400', count: 3
      assert_selector 'p', text: '4.0'
      assert_selector 'p', text: 'з 5 · 2 оцінки'
    end

    test 'a guest sees the average and a login prompt instead of buttons' do
      FictionRating.create!(fiction: @fiction, user: users(:user_two), rating: 4)

      render_inline(RatingCardComponent.new(fiction: @fiction.reload, user: nil))

      assert_no_selector 'button'
      assert_selector '.fill-amber-400', count: 4
      assert_selector 'a[href^="/login"]', text: 'Увійдіть,'
    end

    test 'no ratings yet shows a dash' do
      render_inline(RatingCardComponent.new(fiction: @fiction.reload, user: nil))

      assert_selector 'p', text: '—'
      assert_selector 'p', text: 'з 5 · 0 оцінок'
    end
  end
end
