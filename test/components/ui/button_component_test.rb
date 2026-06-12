# frozen_string_literal: true

require 'test_helper'

module Ui
  class ButtonComponentTest < ViewComponentTestCase
    test 'renders primary button with cyan light and rose dark tokens' do
      render_inline(ButtonComponent.new(label: 'Зберегти', variant: :primary))

      assert_selector 'button[type="button"].bg-cyan-700.text-white.border-cyan-800', text: 'Зберегти'
      assert_selector 'button.dark\\:bg-rose-600.dark\\:border-rose-400'
    end

    test 'renders ghost button with stone and zinc tokens' do
      render_inline(ButtonComponent.new(label: 'Детальніше', variant: :ghost))

      assert_selector 'button.border-stone-200.bg-transparent.text-stone-700'
      assert_selector 'button.dark\\:border-zinc-700.dark\\:bg-transparent'
      assert_no_selector 'button.bg-white, button.dark\\:bg-zinc-900'
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

      assert_selector 'button.text-xs.px-2\\.5'
      assert_includes rendered_content, 'py-0.5'

      render_inline(ButtonComponent.new(label: 'Середній', size: :md))

      assert_selector 'button.px-5.py-2\\.5.text-sm'
    end

    test 'applies responsive size classes across breakpoints' do
      render_inline(ButtonComponent.new(label: 'Читати', size: :responsive))

      assert_selector 'button.text-xs.px-2\\.5'
      assert_selector 'button.md\\:rounded-lg.md\\:px-5.md\\:py-2\\.5.md\\:text-sm'
      assert_no_selector 'button.sm\\:px-2\\.5'
    end

    test 'applies full width class' do
      render_inline(ButtonComponent.new(label: 'На всю ширину', full_width: true))

      assert_selector 'button.w-full'
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
        ButtonComponent.new(label: 'X', variant: :overlay)
      end
    end

    test 'rejects unknown size' do
      assert_raises(ArgumentError) do
        ButtonComponent.new(label: 'X', size: :sm)
      end
    end
  end
end
