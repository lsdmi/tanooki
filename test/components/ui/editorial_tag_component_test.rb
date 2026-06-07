# frozen_string_literal: true

require 'test_helper'

module Ui
  class EditorialTagComponentTest < ViewComponentTestCase
    test 'renders default adult label text' do
      render_inline(EditorialTagComponent.new(kind: :adult))

      assert_text '18+'
    end

    test 'renders default adult label styles' do
      render_inline(EditorialTagComponent.new(kind: :adult))

      assert_selector 'span.rounded-lg'
      assert_selector 'span.md\\:rounded-xl'
      assert_selector 'span.bg-rose-600.text-white'
    end

    test 'renders default adult label without orange background' do
      render_inline(EditorialTagComponent.new(kind: :adult))

      assert_no_selector 'span.bg-orange-600'
    end

    test 'renders custom label' do
      render_inline(EditorialTagComponent.new(kind: :popular, label: 'Рекомендовано'))

      assert_text 'Рекомендовано'
    end

    test 'uses solid background without drop shadow' do
      render_inline(EditorialTagComponent.new(kind: :novelty))

      assert_selector 'span.bg-violet-600'
      assert_no_selector 'span.bg-gradient-to-r'
      assert_no_selector 'span[class*="shadow-"]'
    end

    test 'renders update label with refresh icon' do
      render_inline(EditorialTagComponent.new(kind: :update))

      assert_text 'Оновлення'
      assert_selector 'svg path[d*="13.803-3.7"]'
    end

    test 'rejects unknown kind' do
      assert_raises(ArgumentError) do
        EditorialTagComponent.new(kind: :unknown)
      end
    end
  end
end
