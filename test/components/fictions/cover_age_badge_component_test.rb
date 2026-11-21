# frozen_string_literal: true

require 'test_helper'

module Fictions
  class CoverAgeBadgeComponentTest < ViewComponentTestCase
    setup { @fiction = fictions(:one) }

    test 'renders nothing for an unrated fiction' do
      @fiction.content_rating = :everyone
      render_inline(CoverAgeBadgeComponent.new(fiction: @fiction))

      assert_no_selector 'span'
    end

    test '16+ is an orange icon mark in the top-right corner, labelled for assistive tech' do
      @fiction.content_rating = :sixteen
      render_inline(CoverAgeBadgeComponent.new(fiction: @fiction))

      assert_selector 'span.absolute.right-1.top-1.text-orange-400[role="img"][aria-label="16+"] svg.size-5'
      assert_no_text '16+'
    end

    test '18+ is a red icon mark on a faint dark disc' do
      @fiction.content_rating = :eighteen
      render_inline(CoverAgeBadgeComponent.new(fiction: @fiction))

      assert_selector 'span.text-red-500[role="img"][aria-label="18+"] svg'
      assert_selector 'span.bg-black\/20'
    end

    test 'a shelf rating can be drawn inline on the page background, in the same hues' do
      render_inline(CoverAgeBadgeComponent.new(rating: 'eighteen', placement: :inline))

      assert_selector 'span.inline-flex.text-red-600[role="img"][aria-label="18+"] svg'
      assert_no_selector 'span.absolute'
    end

    test 'the corner can be the left one' do
      render_inline(CoverAgeBadgeComponent.new(rating: 'sixteen', placement: :corner_left))

      assert_selector 'span.absolute.left-1.top-1.text-orange-400 svg'
      assert_no_selector 'span.right-1'
    end

    test 'the icon takes its colour from the text colour and is decorative' do
      @fiction.content_rating = :sixteen
      render_inline(CoverAgeBadgeComponent.new(fiction: @fiction))

      assert_selector 'svg[aria-hidden="true"] path[fill="currentColor"]'
      assert_no_selector 'svg path[fill="#0F0F0F"]'
    end

    test 'decorative marks are hidden from assistive tech' do
      @fiction.content_rating = :eighteen
      render_inline(CoverAgeBadgeComponent.new(fiction: @fiction, decorative: true))

      assert_selector 'span[aria-hidden="true"] svg'
      assert_no_selector 'span[role="img"]'
    end

    test 'sizes pick the icon and box classes' do
      @fiction.content_rating = :sixteen
      render_inline(CoverAgeBadgeComponent.new(fiction: @fiction, size: :sm))

      assert_selector 'span.right-1.top-1 svg.size-4'
    end
  end
end
