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

    test 'a guest sees the work rating copy' do
      render_inline(RatingCardComponent.new(fiction: @fiction, user: nil))

      assert_selector 'h2', text: 'Оцінка твору'
      assert_text 'Середня оцінка читачів за сам твір, від 1 до 5 зірок.'
      assert_text 'щоб оцінити твір'
    end

    test 'no ratings yet shows a dash' do
      render_inline(RatingCardComponent.new(fiction: @fiction.reload, user: nil))

      assert_selector 'p', text: '—'
      assert_selector 'p', text: 'з 5 · 0 оцінок'
    end

    test 'shows the fiction thanks total under the stars when there are any' do
      @fiction.define_singleton_method(:thanks_count) { 2 }
      render_inline(RatingCardComponent.new(fiction: @fiction, user: nil))

      assert_text I18n.t('chapters.thanks.fiction_total')
      assert_text '2 подяки'
    end

    test 'hides the fiction thanks total when nobody has thanked' do
      @fiction.define_singleton_method(:thanks_count) { 0 }
      render_inline(RatingCardComponent.new(fiction: @fiction, user: nil))

      assert_no_text I18n.t('chapters.thanks.fiction_total')
    end
  end
end
