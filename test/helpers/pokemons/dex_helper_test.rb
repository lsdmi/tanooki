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

    test 'dex_title gives a trainer without battles the first title' do
      assert_equal 'Новачок', dex_title(nil)
    end

    test 'dex_title maps a percentile to its band' do
      assert_equal(['Новачок', 'Юнак', 'Власник значка', 'Лідер стадіону', 'Майстер покемонів', 'Чемпіон'],
                   [0.0, 0.15, 0.6, 0.9, 0.96, 0.99].map { |percentile| dex_title(percentile) })
      assert_equal 'Елітна четвірка', dex_title(0.989)
    end

    test 'every title band has a label' do
      assert_equal TITLE_PERCENTILES.size, t('pokemons.titles').size
    end
  end
end
