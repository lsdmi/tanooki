# frozen_string_literal: true

require 'test_helper'

module Fictions
  class GenresPromoHelperTest < ActionView::TestCase
    include GenresPromoHelper

    test 'fiction_genre_promo_card for guest points to login' do
      define_singleton_method(:user_signed_in?) { false }

      card = fiction_genre_promo_card

      assert_equal new_user_session_path, card[:href]
      assert_equal 'Увійти та почати писати', card[:button_label]
    end

    test 'fiction_genre_promo_card for guest includes authors badge' do
      define_singleton_method(:user_signed_in?) { false }

      card = fiction_genre_promo_card

      assert_equal 'Для авторів', card[:badge_label]
      assert card[:button_arrow]
    end

    test 'fiction_genre_promo_card for signed-in user points to writings studio' do
      define_singleton_method(:user_signed_in?) { true }

      card = fiction_genre_promo_card

      assert_equal readings_path, card[:href]
      assert_equal 'Відкрити писальню', card[:button_label]
    end
  end
end
