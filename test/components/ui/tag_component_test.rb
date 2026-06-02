# frozen_string_literal: true

require 'test_helper'

module Ui
  class TagComponentTest < ViewComponentTestCase
    test 'renders outlined keyword classes' do
      render_inline(TagComponent.new(label: 'аніме', variant: :keyword, href: '/search'))

      assert_selector 'a.border-gray-300.bg-white.text-gray-800.dark\\:bg-gray-900.dark\\:border-zinc-500'
      assert_no_selector 'a.bg-cyan-700, a.bg-orange-600'
    end

    test 'renders filter with primary cyan in light and red in dark' do
      render_inline(TagComponent.new(label: 'аніме', variant: :filter, href: '/search'))

      assert_selector 'a.border-cyan-800.bg-cyan-700.text-white'
      assert_selector 'a.dark\\:border-rose-400.dark\\:bg-rose-600'
    end

    test 'renders current keyword as filter style' do
      render_inline(
        TagComponent.new(label: 'аніме', variant: :keyword, href: '/search', current: true)
      )

      assert_selector 'a.bg-cyan-700.text-white[aria-current="page"]'
    end

    test 'renders static outlined status tag' do
      render_inline(TagComponent.new(label: 'Completed', variant: :status))

      assert_selector 'span.border-gray-300.bg-white'
      assert_selector 'span.dark\\:bg-gray-900'
      assert_no_selector 'a'
    end

    test 'renders adult with darker red border in light and lighter in dark' do
      render_inline(TagComponent.new(label: '18+', variant: :adult))

      assert_selector 'span.border-orange-800.bg-orange-600.text-white'
      assert_selector 'span.dark\\:border-orange-400.dark\\:bg-orange-600'
    end

    test 'renders count badge on outlined keyword' do
      render_inline(TagComponent.new(label: 'аніме', variant: :keyword, href: '/search', count: 12))

      assert_selector 'a span.bg-cyan-100.text-cyan-700', text: '12'
      assert_selector 'a span.dark\\:bg-zinc-600.dark\\:text-zinc-100', text: '12'
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

      assert_selector 'button[type="button"].bg-cyan-700', text: /Усе/
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
