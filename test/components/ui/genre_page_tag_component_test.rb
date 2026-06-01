# frozen_string_literal: true

require 'test_helper'

module Ui
  class GenrePageTagComponentTest < ViewComponentTestCase
    test 'renders featured rank badge' do
      render_inline(GenrePageTagComponent.new(variant: :rank, label: '1', rank_size: :featured))

      assert_selector 'span.border-slate-600\\/55.bg-slate-400\\/45.text-sm.font-bold', text: '1'
      assert_selector 'span.dark\\:border-slate-300\\/45.dark\\:bg-slate-900\\/55.dark\\:text-white'
      assert_selector 'span[aria-label="Місце в рейтингу: 1"]'
    end

    test 'renders thumb rank badge' do
      render_inline(GenrePageTagComponent.new(variant: :rank, label: '3', rank_size: :thumb))

      assert_selector 'span.border-slate-500\\/70.bg-white\\/55.text-xs.font-bold', text: '3'
      assert_selector 'span.dark\\:border-slate-400\\/50.dark\\:bg-slate-900\\/55'
    end

    test 'renders cover stat tags with icons' do
      render_inline(GenrePageTagComponent.new(variant: :stat_views, label: '526'))

      assert_selector 'span.bg-black\\/40 svg', count: 1
      assert_selector 'span .tabular-nums', text: '526'

      render_inline(GenrePageTagComponent.new(variant: :stat_rating, label: '4.3'))

      assert_selector 'span.text-amber-300', text: '4.3'
    end

    test 'renders footer chapters and status tags' do
      render_inline(GenrePageTagComponent.new(variant: :chapters, label: '252 Розділи'))

      assert_selector 'span.border-slate-400\\/90.bg-slate-100', text: '252 Розділи'
      assert_selector 'span.dark\\:bg-slate-700\\/80.dark\\:text-slate-200', text: '252 Розділи'

      render_inline(GenrePageTagComponent.new(variant: :status, label: 'Покинуто'))

      assert_selector 'span.border-slate-300\\/90.bg-slate-50', text: 'Покинуто'
      assert_selector 'span.dark\\:text-slate-300', text: 'Покинуто'
    end

    test 'renders genre link' do
      render_inline(GenrePageTagComponent.new(variant: :genre, label: 'Бойовик', href: '/fictions/genres/action'))

      assert_selector 'a.bg-slate-800\\/85.text-slate-200', text: 'Бойовик'
      assert_selector 'a.dark\\:hover\\:border-slate-300\\/55.dark\\:focus-visible\\:ring-slate-400'
    end

    test 'rejects unknown variant' do
      assert_raises(ArgumentError) do
        GenrePageTagComponent.new(variant: :unknown, label: 'x')
      end
    end
  end
end
