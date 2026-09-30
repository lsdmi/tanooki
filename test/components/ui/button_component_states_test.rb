# frozen_string_literal: true

require 'test_helper'

module Ui
  class ButtonComponentStatesTest < ViewComponentTestCase
    test 'icon-only button is square and labelled for screen readers' do
      render_inline(ButtonComponent.new(label: 'Закрити', icon_only: true, variant: :ghost, size: :md)) do
        '<svg class="size-4"></svg>'.html_safe
      end

      assert_selector 'button.size-9.rounded-lg[aria-label="Закрити"] svg.size-4'
      assert_no_text 'Закрити'
      assert_no_selector 'button.px-4'
    end

    test 'icon-only button keeps a caller aria label' do
      render_inline(ButtonComponent.new(label: 'Меню', icon_only: true, html: { aria: { label: 'Дії з розділом' } })) do
        '<svg></svg>'.html_safe
      end

      assert_selector 'button[aria-label="Дії з розділом"]'
    end

    test 'loading disables the button, marks it busy and shows a spinner before the label' do
      render_inline(ButtonComponent.new(label: 'Зберегти', loading: true))

      assert_selector 'button[disabled][aria-busy="true"] svg.animate-spin'
      assert_selector 'button', text: 'Зберегти'
    end

    test 'loading icon-only button swaps the icon for the spinner' do
      render_inline(ButtonComponent.new(label: 'Оновити', icon_only: true, loading: true)) do
        '<svg class="icon-refresh"></svg>'.html_safe
      end

      assert_selector 'button[aria-busy="true"] svg.animate-spin'
      assert_no_selector 'svg.icon-refresh'
    end

    test 'disabled button gets the disabled attribute' do
      render_inline(ButtonComponent.new(label: 'Недоступно', disabled: true))

      assert_selector 'button[disabled].disabled\\:opacity-50'
      assert_no_selector 'button[aria-busy]'
    end

    test 'disabled link is inert without dropping its href' do
      render_inline(ButtonComponent.new(label: 'Завантажити', as: :link, href: '/file', disabled: true))

      assert_selector 'a[href="/file"][aria-disabled="true"][tabindex="-1"].pointer-events-none.opacity-50'
    end
  end
end
