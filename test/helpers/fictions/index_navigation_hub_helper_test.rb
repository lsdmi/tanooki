# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexNavigationHubHelperTest < ActionView::TestCase
    include IndexNavigationHubHelper

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

    test 'library card for guest points to login' do
      define_singleton_method(:user_signed_in?) { false }

      library = fiction_index_navigation_hub_cards.find { |card| card[:title] == 'Читальня' }

      assert_equal new_user_session_path, library[:href]
      assert_equal 'Увійти до читальні', library[:button_label]
    end

    test 'library card for signed-in user points to library' do
      define_singleton_method(:user_signed_in?) { true }

      library = fiction_index_navigation_hub_cards.find { |card| card[:title] == 'Читальня' }

      assert_equal library_path, library[:href]
      assert_equal 'Відкрити читальню', library[:button_label]
    end

    test 'hub cards use dedicated background images' do
      define_singleton_method(:user_signed_in?) { false }

      images = fiction_index_navigation_hub_cards.pluck(:background_image)

      assert_equal %w[
        fiction-index-hub-storage.webp
        fiction-index-hub-calendar.webp
        fiction-index-hub-library.webp
      ], images
    end
  end
end
