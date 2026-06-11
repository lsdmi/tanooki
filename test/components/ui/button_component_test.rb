# frozen_string_literal: true

require 'test_helper'

module Ui
  class ButtonComponentTest < ViewComponentTestCase
    test 'renders primary button with cyan light and rose dark tokens' do
      render_inline(ButtonComponent.new(label: 'Зберегти', variant: :primary))

      assert_selector 'button[type="button"].bg-cyan-700.text-white.border-cyan-800', text: 'Зберегти'
      assert_selector 'button.dark\\:bg-rose-600.dark\\:border-rose-400'
    end

    test 'renders secondary outlined button' do
      render_inline(ButtonComponent.new(label: 'Скасувати', variant: :secondary))

      assert_selector 'button.border-cyan-700.bg-white.text-cyan-700'
      assert_selector 'button.dark\\:border-rose-600.dark\\:bg-gray-800.dark\\:text-rose-400'
    end

    test 'renders ghost button with stone and zinc tokens' do
      render_inline(ButtonComponent.new(label: 'Детальніше', variant: :ghost))

      assert_selector 'button.border-stone-200.bg-white.text-stone-700'
      assert_selector 'button.dark\\:border-zinc-700.dark\\:bg-zinc-900'
    end

    test 'renders link when as is link' do
      render_inline(ButtonComponent.new(label: 'Увійти', as: :link, href: '/login'))

      assert_selector 'a[href="/login"].bg-cyan-700', text: 'Увійти'
      assert_no_selector 'button'
    end

    test 'renders submit button' do
      render_inline(ButtonComponent.new(label: 'Опублікувати', as: :submit))

      assert_selector 'button[type="submit"]', text: 'Опублікувати'
    end

    test 'applies size classes' do
      render_inline(ButtonComponent.new(label: 'Малий', size: :xs))

      assert_selector 'button.text-2xs.px-2'
      assert_includes rendered_content, 'py-0.5'

      render_inline(ButtonComponent.new(label: 'Великий', size: :lg))

      assert_selector 'button.px-6.py-3.font-semibold'
    end

    test 'applies full width class' do
      render_inline(ButtonComponent.new(label: 'На всю ширину', full_width: true))

      assert_selector 'button.w-full'
    end

    test 'disables native button' do
      render_inline(ButtonComponent.new(label: 'Недоступно', disabled: true))

      assert_selector 'button[disabled]'
    end

    test 'renders disabled link as span' do
      render_inline(ButtonComponent.new(label: 'Недоступно', as: :link, href: '/x', disabled: true))

      assert_selector 'span[role="link"][aria-disabled="true"][tabindex="-1"]', text: 'Недоступно'
      assert_no_selector 'a'
    end

    test 'merges html data attributes' do
      render_inline(
        ButtonComponent.new(
          label: 'Дія',
          html: { data: { action: 'click->foo#bar' } }
        )
      )

      assert_selector 'button[data-action="click->foo#bar"]'
    end

    test 'renders slot content instead of label' do
      render_inline(ButtonComponent.new(variant: :primary)) do
        '<svg class="h-4 w-4"></svg><span>З іконкою</span>'.html_safe
      end

      assert_selector 'button svg.h-4.w-4'
      assert_selector 'button span', text: 'З іконкою'
    end

    test 'rejects link without href' do
      assert_raises(ArgumentError) do
        ButtonComponent.new(label: 'Без URL', as: :link)
      end
    end

    test 'rejects unknown variant' do
      assert_raises(ArgumentError) do
        ButtonComponent.new(label: 'X', variant: :danger)
      end
    end
  end
end
