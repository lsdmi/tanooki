# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class DexHelperTest < ActionView::TestCase
    include DexHelper

    test 'battle_result_badge names the outcome in its status colour' do
      render html: battle_result_badge(true) + battle_result_badge(false)

      assert_select 'span.bg-status-success-subtle-bg', text: 'Перемога'
      assert_select 'span.bg-status-danger-subtle-bg', text: 'Поразка'
      assert_select 'svg[aria-hidden=true]', count: 2
    end

    test 'dex_title should return the correct title for case 0' do
      title = dex_title(4)

      assert_equal 'Початківець', title
    end

    test 'dex_title should return the correct title for case 21' do
      title = dex_title(41)

      assert_equal 'Школяр', title
    end

    test 'dex_title should return the correct title for case 41' do
      title = dex_title(59)

      assert_equal 'Тренер', title
    end

    test 'dex_title should return the correct title for case 61' do
      title = dex_title(83)

      assert_equal 'Висхідна зірка', title
    end

    test 'dex_title should return the correct title for case 81' do
      title = dex_title(93)

      assert_equal 'Майстер', title
    end

    test 'dex_title should return the correct title for case 91' do
      title = dex_title(99)

      assert_equal 'Чемпіон', title
    end
  end
end
