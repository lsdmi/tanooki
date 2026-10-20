# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexNavigationHubHelperTest < ActionView::TestCase
    include IndexNavigationHubHelper

    test 'hub card order is writings, storage, calendar' do
      define_singleton_method(:user_signed_in?) { false }

      assert_equal ['Твори із Бакою', 'Сховище', 'Календар'],
                   fiction_index_navigation_hub_cards.pluck(:title)
    end

    test 'writings card for guest points to login' do
      define_singleton_method(:user_signed_in?) { false }

      writings = fiction_index_navigation_hub_cards.find { |card| card[:title] == 'Твори із Бакою' }

      assert_equal new_user_session_path, writings[:href]
      assert_equal 'Увійти та почати писати', writings[:button_label]
    end

    test 'writings card for signed-in user points to studio writings' do
      define_singleton_method(:user_signed_in?) { true }

      writings = fiction_index_navigation_hub_cards.find { |card| card[:title] == 'Твори із Бакою' }

      assert_equal readings_path, writings[:href]
      assert_equal 'Відкрити писальню', writings[:button_label]
    end

    test 'storage card points to the alphabetical catalog' do
      define_singleton_method(:user_signed_in?) { false }

      storage = fiction_index_navigation_hub_cards.find { |card| card[:title] == 'Сховище' }

      assert_equal alphabetical_fictions_path, storage[:href]
      assert_equal 'Відкрити сховище', storage[:button_label]
    end

    test 'calendar card points to the chapters calendar' do
      define_singleton_method(:user_signed_in?) { false }

      calendar = fiction_index_navigation_hub_cards.find { |card| card[:title] == 'Календар' }

      assert_equal calendar_fictions_path, calendar[:href]
      assert_equal 'Відкрити календар', calendar[:button_label]
    end

    test 'hub cards use dedicated background images' do
      define_singleton_method(:user_signed_in?) { false }

      images = fiction_index_navigation_hub_cards.pluck(:background_image)

      assert_equal %w[
        fiction-genre-writings-promo.webp
        fiction-index-hub-storage.webp
        fiction-index-hub-calendar.webp
      ], images
    end
  end
end
