# frozen_string_literal: true

require 'test_helper'

module Ui
  class MenuItemComponentTest < ViewComponentTestCase
    test 'renders a plain button row with an icon' do
      render_inline(MenuItemComponent.new(label: 'Читаю')) do |item|
        item.with_icon { '<svg class="icon-book"></svg>'.html_safe }
      end

      assert_selector 'button[type="button"].min-h-9.text-fg.hover\\:bg-surface-hover span[aria-hidden] svg.icon-book'
      assert_no_selector 'button[aria-current]'
    end

    test 'selected row is tinted, marked current and shows a check' do
      render_inline(MenuItemComponent.new(label: 'Читаю', tone: :selected))

      assert_selector 'button.bg-brand-subtle.text-fg-brand[aria-current="true"] svg path[d="M20 6 9 17l-5-5"]'
    end

    test 'destructive row uses the danger color' do
      render_inline(MenuItemComponent.new(label: 'Прибрати з бібліотеки', tone: :destructive))

      assert_selector 'button.text-status-danger-solid', text: 'Прибрати з бібліотеки'
    end

    test 'renders a link and merges html attributes' do
      render_inline(MenuItemComponent.new(label: 'Відкрити', as: :link, href: '/x',
                                          html: { class: 'font-medium', data: { turbo: false } }))

      assert_selector 'a[href="/x"][data-turbo="false"].font-medium', text: 'Відкрити'
    end

    test 'rejects a link without href, unknown tones and element types' do
      assert_raises(ArgumentError) { MenuItemComponent.new(label: 'X', as: :link) }
      assert_raises(ArgumentError) { MenuItemComponent.new(label: 'X', as: :div) }
      assert_raises(ArgumentError) { MenuItemComponent.new(label: 'X', tone: :muted) }
    end
  end
end
