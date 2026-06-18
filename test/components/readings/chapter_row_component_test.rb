# frozen_string_literal: true

require 'test_helper'

module Readings
  class ChapterRowComponentTest < ViewComponentTestCase
    include Rails.application.routes.url_helpers

    setup do
      @chapter = chapters(:one)
    end

    test 'renders table row variant' do
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 2))

      assert_selector 'tr'
      assert_selector 'th[scope="row"] a', text: @chapter.display_title
      assert_selector "a[href='#{chapter_path(@chapter)}'][title='Переглянути']"
    end

    test 'renders table row delete action with pagy page' do
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 2))

      assert_selector "a[href='#{edit_chapter_path(@chapter.slug)}']"
      assert_selector "button.sweet-alert-button[data-url='#{reading_path(@chapter, page: 2)}']"
    end

    test 'renders card variant' do
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :card, pagy_page: 1))

      assert_no_selector 'tr'
      assert_selector '.rounded-lg.border', text: @chapter.display_title
      assert_selector "button.sweet-alert-button[data-url='#{reading_path(@chapter, page: 1)}']"
    end

    test 'rejects unknown variant' do
      assert_raises(ArgumentError) do
        ChapterRowComponent.new(chapter: @chapter, variant: :grid)
      end
    end
  end
end
