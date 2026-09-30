# frozen_string_literal: true

require 'test_helper'

module Ui
  class TagComponentTest < ViewComponentTestCase
    test 'renders outlined keyword classes' do
      render_inline(TagComponent.new(label: 'аніме', variant: :keyword, href: '/search'))

      assert_selector 'a.border-line-strong.bg-main.text-fg'
      assert_no_selector 'a.bg-brand, a.bg-rose-200'
    end

    test 'renders filter with brand token' do
      render_inline(TagComponent.new(label: 'аніме', variant: :filter, href: '/search'))

      assert_selector 'a.border-brand-hover.bg-brand.text-fg-on-brand'
    end

    test 'renders current keyword as filter style' do
      render_inline(
        TagComponent.new(label: 'аніме', variant: :keyword, href: '/search', current: true)
      )

      assert_selector 'a.bg-brand.text-fg-on-brand[aria-current="page"]'
    end

    test 'renders static outlined status tag' do
      render_inline(TagComponent.new(label: 'Completed', variant: :status))

      assert_selector 'span.border-line-strong.bg-main'
      assert_no_selector 'a'
    end

    test 'renders adult with rose-200 fill rose-700 border and rose-800 text' do
      render_inline(TagComponent.new(label: '18+', variant: :adult))

      assert_selector 'span.border-rose-700.bg-rose-200.text-rose-800'
      assert_selector 'span.bg-rose-200 svg'
      assert_no_selector 'span.text-white'
    end

    test 'renders eighteen rating with rose classes' do
      render_inline(TagComponent.new(label: '18+', variant: :eighteen))

      assert_selector 'span.border-rose-700.bg-rose-200.text-rose-800'
      assert_selector 'span.bg-rose-200 svg'
    end

    test 'renders sixteen rating with amber classes' do
      render_inline(TagComponent.new(label: '16+', variant: :sixteen))

      assert_selector 'span.border-amber-800.bg-amber-200.text-amber-900'
      assert_selector 'span.bg-amber-200 svg'
    end

    test 'rejects count on adult variant' do
      assert_raises(ArgumentError) do
        TagComponent.new(label: '18+', variant: :adult, count: 3)
      end
    end

    test 'rejects count on sixteen variant' do
      assert_raises(ArgumentError) do
        TagComponent.new(label: '16+', variant: :sixteen, count: 3)
      end
    end

    test 'renders count badge on outlined keyword' do
      render_inline(TagComponent.new(label: 'аніме', variant: :keyword, href: '/search', count: 12))

      assert_selector 'a span.bg-brand-subtle.text-fg-brand', text: '12'
      assert_selector 'a span.dark\\:bg-surface-hover.dark\\:text-fg', text: '12'
    end

    test 'renders count badge on solid filter' do
      render_inline(TagComponent.new(label: 'аніме', variant: :filter, href: '/search', count: 12))

      assert_selector 'a span.bg-white\\/25.text-white', text: '12'
    end

    test 'renders button with filter variant and count' do
      render_inline(
        TagComponent.new(
          label: 'Усе',
          variant: :filter,
          size: :md,
          count: 0,
          as: :button,
          html: { data: { action: 'click->search-filter#filter' } }
        )
      )

      assert_selector 'button[type="button"].bg-brand', text: /Усе/
      assert_selector 'button span', text: '0'
      assert_no_selector 'a'
    end

    test 'rejects unknown variant' do
      assert_raises(ArgumentError) do
        TagComponent.new(label: 'x', variant: :unknown)
      end
    end
  end
end
