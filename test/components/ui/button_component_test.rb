# frozen_string_literal: true

require 'test_helper'

module Ui
  class ButtonComponentTest < ViewComponentTestCase
    test 'renders primary button with brand tokens' do
      render_inline(ButtonComponent.new(label: 'Зберегти', variant: :primary))

      assert_selector 'button[type="button"].bg-brand.text-fg-on-brand.hover\\:bg-brand-hover', text: 'Зберегти'
      assert_no_selector 'button[class*="dark:"]'
    end

    test 'renders outline, ghost, destructive and licensed variants with tokens' do
      {
        outline: 'button.border-line.bg-transparent.text-fg.hover\\:bg-surface',
        ghost: 'button.bg-transparent.text-fg.hover\\:bg-surface',
        destructive: 'button.bg-btn-destructive.text-fg-on-brand.hover\\:bg-btn-destructive-hover',
        licensed: 'button.bg-btn-licensed.text-fg-on-brand.hover\\:bg-btn-licensed-hover'
      }.each do |variant, selector|
        render_inline(ButtonComponent.new(label: 'Дія', variant:))

        assert_selector selector, text: 'Дія'
      end
    end

    test 'ghost has no visible border' do
      render_inline(ButtonComponent.new(label: 'Скасувати', variant: :ghost))

      assert_selector 'button.border-transparent'
      assert_no_selector 'button.border-line'
      assert_no_selector 'button.shadow-xs'
    end

    test 'outline border is not cancelled by a competing border color' do
      render_inline(ButtonComponent.new(label: 'Детальніше', variant: :outline))

      assert_selector 'button.border-line.shadow-xs'
      assert_no_selector 'button.border-transparent'
    end

    test 'renders link when as is link' do
      render_inline(ButtonComponent.new(label: 'Увійти', as: :link, href: '/login'))

      assert_selector 'a[href="/login"].bg-brand', text: 'Увійти'
      assert_no_selector 'button'
    end

    test 'renders submit button' do
      render_inline(ButtonComponent.new(label: 'Опублікувати', as: :submit))

      assert_selector 'button[type="submit"]', text: 'Опублікувати'
    end

    test 'sizes follow the Figma ramp and default to lg' do
      render_inline(ButtonComponent.new(label: 'Типовий'))

      assert_selector 'button.min-h-10.px-4.text-sm'

      render_inline(ButtonComponent.new(label: 'Середній', size: :md))

      assert_selector 'button.min-h-9.px-4.text-sm'

      render_inline(ButtonComponent.new(label: 'Малий', size: :sm))

      assert_selector 'button.min-h-8.px-3.text-xs'
    end

    test 'keeps the legacy xs size' do
      render_inline(ButtonComponent.new(label: 'Малий', size: :xs))

      assert_selector 'button.text-xs.px-2\\.5'
      assert_includes rendered_content, 'py-0.5'
    end

    test 'applies responsive size classes across breakpoints' do
      render_inline(ButtonComponent.new(label: 'Читати', size: :responsive))

      assert_selector 'button.text-xs.px-2\\.5'
      assert_selector 'button.md\\:rounded-lg.md\\:px-5.md\\:py-2\\.5.md\\:text-sm'
    end

    test 'applies responsive_banner size between xs and lg below md breakpoint' do
      render_inline(ButtonComponent.new(label: 'До оповідей', size: :responsive_banner))

      assert_selector 'button.rounded-md.px-4.py-1\\.5.text-xs'
      assert_selector 'button.md\\:rounded-lg.md\\:px-5.md\\:py-2\\.5.md\\:text-sm'
    end

    test 'fab is round' do
      render_inline(ButtonComponent.new(label: 'Чат', size: :fab))

      assert_selector 'button.rounded-full.p-4.shadow-lg'
      assert_no_selector 'button.shadow-xs'
    end

    test 'applies full width class' do
      render_inline(ButtonComponent.new(label: 'На всю ширину', full_width: true))

      assert_selector 'button.w-full'
    end

    test 'merges html data and aria attributes' do
      render_inline(
        ButtonComponent.new(
          label: 'Дія',
          html: { data: { action: 'click->foo#bar' }, aria: { controls: 'panel' }, class: 'shrink-0' }
        )
      )

      assert_selector 'button.shrink-0.bg-brand[data-action="click->foo#bar"][aria-controls="panel"]'
    end

    test 'renders slot content instead of label' do
      render_inline(ButtonComponent.new(variant: :primary)) do
        '<svg class="h-4 w-4"></svg><span>З іконкою</span>'.html_safe
      end

      assert_selector 'button svg.h-4.w-4'
      assert_selector 'button span', text: 'З іконкою'
    end

    test 'rejects link without href' do
      assert_raises(ArgumentError) { ButtonComponent.new(label: 'Без URL', as: :link) }
    end

    test 'rejects unknown variant and size' do
      assert_raises(ArgumentError) { ButtonComponent.new(label: 'X', variant: :secondary) }
      assert_raises(ArgumentError) { ButtonComponent.new(label: 'X', size: :xl) }
    end

    test 'icon-only needs a label and a square size' do
      assert_raises(ArgumentError) { ButtonComponent.new(icon_only: true) }
      assert_raises(ArgumentError) { ButtonComponent.new(label: 'X', icon_only: true, size: :xs) }
    end
  end
end
