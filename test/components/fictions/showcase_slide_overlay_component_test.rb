# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ShowcaseSlideOverlayComponentTest < ViewComponentTestCase
    SampleFiction = Struct.new(:title, :description, :author, :average_rating, :views, keyword_init: true)

    def setup
      @fiction = SampleFiction.new(
        title: 'Точка зору всезнаючого читача',
        description: 'Життя Кіма Докджі обертається навколо читання одного веб-роману.',
        author: 'singNsong',
        average_rating: 4.9,
        views: 25_700
      )
      @links = { read: '/read', fiction: '/fiction' }
    end

    test 'mobile minimal hides metadata and buttons' do
      render_inline(component(layout: :mobile_minimal))

      assert_text 'Точка зору всезнаючого читача'
      assert_text 'Оновлення'
      assert_no_text 'Читати зараз'
    end

    test 'mobile minimal uses single-line title and asymmetric padding' do
      render_inline(component(layout: :mobile_minimal))

      assert_selector 'h2.line-clamp-1'
      assert_selector '.pl-4.pr-8'
    end

    test 'mobile minimal hides author metadata' do
      render_inline(component(layout: :mobile_minimal))

      assert_no_text 'singNsong'
    end

    test 'full layout shows metadata and buttons' do
      render_inline(component(layout: :full, editorial_kinds: %i[popular]))

      assert_text 'Читати зараз'
      assert_text 'singNsong'
      assert_text '4,9'
    end

    test 'responsive layout uses mobile hiding utilities' do
      render_inline(component(layout: :responsive))

      assert_selector '[class*="max-sm:hidden"]', text: 'Читати зараз'
      assert_selector 'h2.line-clamp-1'
      assert_selector '.max-sm\\:pl-4.max-sm\\:pr-8'
    end

    private

    def component(layout:, editorial_kinds: %i[update])
      ShowcaseSlideOverlayComponent.new(
        fiction: @fiction,
        editorial_kinds: editorial_kinds,
        links: @links,
        layout: layout
      )
    end
  end
end
