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

    test 'extra classes join the shell' do
      render_inline(PanelComponent.new(title: 'Топ тренерів', html: { class: 'lg:flex-1', data: { qa: 'top' } }))

      assert_selector 'section.rounded-xl.lg\:flex-1[data-qa=top]'
    end
  end
end
