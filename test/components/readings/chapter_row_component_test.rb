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

    test 'draft table row shows badge and points title at edit' do
      @chapter.status = :draft
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 1))

      assert_text I18n.t('chapters.alerts.draft')
      assert_selector "a[href='#{edit_chapter_path(@chapter.slug)}']", text: @chapter.display_title
      assert_no_selector "a[title='Переглянути']"
    end

    test 'scheduled table row shows release hint' do
      @chapter.published_at = 2.days.from_now
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 1))

      assert_text I18n.t('chapters.hints.scheduled_vs_draft')
    end

    test 'renders table row edit and delete actions with pagy page' do
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 2))

      assert_selector "a[href='#{edit_chapter_path(@chapter.slug, page: 2)}']"
      assert_selector "button.sweet-alert-button[data-sweet-alert-url-value='#{reading_path(@chapter, page: 2)}']"
    end

    test 'omits page from edit action on the first page' do
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 1))

      assert_selector "a[href='#{edit_chapter_path(@chapter.slug)}']"
    end

    test 'renders card variant' do
      render_inline(ChapterRowComponent.new(chapter: @chapter, variant: :card, pagy_page: 1))

      assert_no_selector 'tr'
      assert_selector '.rounded-lg.border', text: @chapter.display_title
      assert_selector "button.sweet-alert-button[data-sweet-alert-url-value='#{reading_path(@chapter, page: 1)}']"
    end

    test 'shows the thanks count next to comments' do
      ChapterThank.find_by(user: users(:user_two), chapter: @chapter)&.destroy!
      ChapterThank.create!(user: users(:user_two), chapter: @chapter)
      label = I18n.t('chapters.thanks.studio_label')
      render_inline(ChapterRowComponent.new(chapter: @chapter.reload, variant: :table_row, pagy_page: 1))

      assert_text @chapter.thanks_count.to_s
      assert_selector "[title='#{label}']", text: @chapter.thanks_count.to_s
    end

    test 'shows open paragraph report count when present' do
      label = I18n.t('chapters.paragraph_reports.studio_label', count: 3)
      render_inline(
        ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 1, open_report_count: 3)
      )

      assert_text '3'
      assert_selector "[title='#{label}']", text: '3'
      assert_selector '[role=tooltip]', text: label
    end

    test 'hides open paragraph report count when zero' do
      label = I18n.t('chapters.paragraph_reports.studio_label', count: 0)
      render_inline(
        ChapterRowComponent.new(chapter: @chapter, variant: :table_row, pagy_page: 1, open_report_count: 0)
      )

      assert_no_selector "[title='#{label}']"
    end

    test 'rejects unknown variant' do
      assert_raises(ArgumentError) do
        ChapterRowComponent.new(chapter: @chapter, variant: :grid)
      end
    end
  end
end
