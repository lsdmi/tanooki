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

    test 'mobile minimal shows the title' do
      render_inline(component(layout: :mobile_minimal))

      assert_text 'Точка зору всезнаючого читача'
    end

    test 'mobile minimal hides blurb meta and read link' do
      render_inline(component(layout: :mobile_minimal))

      assert_no_text 'Читати'
      assert_no_text 'Життя Кіма'
      assert_no_text 'singNsong'
    end

    test 'full layout shows title blurb and editorial tag' do
      render_inline(component(layout: :full, editorial_kinds: %i[popular]))

      assert_text 'Точка зору всезнаючого читача'
      assert_text 'Популярне'
      assert_text 'Життя Кіма'
    end

    test 'full layout shows meta and read link' do
      render_inline(component(layout: :full, editorial_kinds: %i[popular]))

      assert_text '4,9'
      assert_text 'singNsong'
      assert_text 'Читати'
    end

    test 'overlay uses the content rail and theme type' do
      rendered = render_inline(component(layout: :responsive))
      html = rendered.to_html

      assert_includes html, 'max-w-[1300px]'
      assert_includes html, 'text-fg'
      assert_includes html, 'dark:text-white'
    end

    test 'responsive layout keeps the blurb visible on small screens' do
      rendered = render_inline(component(layout: :responsive))
      blurb = rendered.css('p').find { |node| node.text.include?('Життя Кіма') }

      assert blurb
      assert_includes blurb['class'], 'line-clamp-2'
      assert_not_includes blurb['class'], 'max-sm:hidden'
    end

    test 'without content rail the overlay skips the page column max width' do
      rendered = render_inline(component(layout: :responsive, content_rail: false))

      assert_no_match(/max-w-\[1300px\]/, rendered.to_html)
      assert_text 'Читати'
    end

    private

    def component(layout:, editorial_kinds: %i[update], content_rail: true)
      ShowcaseSlideOverlayComponent.new(
        fiction: @fiction,
        editorial_kinds: editorial_kinds,
        links: @links,
        layout: layout,
        content_rail: content_rail
      )
    end
  end
end
