# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class PanelComponentTest < ViewComponentTestCase
    test 'a titled section named by its heading, with the content below' do
      render_inline(PanelComponent.new(title: 'Мій виклик', id: 'pokemon-details')) { 'Суперник' }

      heading_id = page.find('h2', text: 'Мій виклик')[:id]

      assert_selector "section#pokemon-details[aria-labelledby='#{heading_id}']", text: 'Суперник'
    end

    test 'an optional subtitle and action' do
      render_inline(PanelComponent.new(title: 'Мої покемони', subtitle: 'У колекції: 27')) do |panel|
        panel.with_action { '<button>Тренувати</button>'.html_safe }
      end

      assert_selector 'h2 + p', text: 'У колекції: 27'
      assert_selector 'button', text: 'Тренувати'
    end

    test 'extra classes join the journal shell' do
      render_inline(PanelComponent.new(title: 'Топ тренерів', html: { class: 'lg:flex-1', data: { qa: 'top' } }))

      assert_selector 'section.border-b.lg\:flex-1[data-qa=top]'
    end

    test 'the arena tone uses a stage shell' do
      render_inline(PanelComponent.new(title: 'Арена', tone: :arena))

      assert_selector 'section.rounded-2xl.bg-surface'
    end

    test 'a folded panel wires the fold controller to a chevron named by the heading' do
      render_inline(PanelComponent.new(title: 'Топ тренерів', fold: 'top'))

      heading_id = page.find('h2', text: 'Топ тренерів')[:id]

      assert_selector "section[data-controller=panel-fold][data-panel-fold-key-value=top][style*='pokemon-top']"
      assert_selector "button[aria-expanded=false][aria-labelledby='#{heading_id}'][data-action='panel-fold#toggle']"
    end

    test 'a panel without a fold has no chevron' do
      render_inline(PanelComponent.new(title: 'Мій виклик'))

      assert_no_selector 'section[data-controller]'
      assert_no_selector 'button'
    end
  end
end
