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

    test 'scout_icon renders decorative binoculars' do
      render html: scout_icon

      assert_select 'svg[aria-hidden=true].size-3\\.5'
      assert_select 'svg path', count: BINOCULARS_PATHS.size
    end

    test 'battle_share_icon renders a decorative external link' do
      render html: battle_share_icon

      assert_select 'svg[aria-hidden=true].size-3\\.5'
      assert_select 'svg path', count: EXTERNAL_LINK_PATHS.size
    end

    test 'defense_away_sentence joins only the non-zero sides' do
      line = defense_away_sentence(DefenseAway::Report.new(2, 1))

      assert_equal 'Поки вас не було · 2 перемоги · 1 поразка', line
      assert_equal 'Поки вас не було · 1 перемога',
                   defense_away_sentence(DefenseAway::Report.new(1, 0))
    end

    test 'daily quest labels use Ukrainian copy' do
      open = TrainerDailyQuest.new(quest_key: 'read_fantasy_chapters', progress: 1, target: 2)
      done = TrainerDailyQuest.new(quest_key: 'catch_pokemon', progress: 1, target: 1,
                                   completed_at: Time.current)

      assert_equal 'Прочитайте 2 розділи фентезі', daily_quest_label(open)
      assert_equal 'Спіймайте покемона', daily_quest_label(done)
    end

    test 'daily quest progress uses Ukrainian copy' do
      open = TrainerDailyQuest.new(quest_key: 'read_fantasy_chapters', progress: 1, target: 2)
      done = TrainerDailyQuest.new(quest_key: 'catch_pokemon', progress: 1, target: 1,
                                   completed_at: Time.current)

      assert_equal '1/2', daily_quest_progress_label(open)
      assert_equal 'готово', daily_quest_progress_label(done)
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
