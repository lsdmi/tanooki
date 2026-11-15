# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ParagraphReportSheetComponentTest < ViewComponent::TestCase
    setup do
      @chapter = chapters(:one)
      @reader = users(:user_two)
    end

    test 'a reader sees the report form' do
      render_inline(ParagraphReportSheetComponent.new(chapter: @chapter, user: @reader))

      assert_selector '#paragraph-report form[data-paragraph-report-target=form] textarea#paragraph-report-message'
      assert_button 'Копіювати абзац'
      assert_button 'Надіслати'
    end

    test 'a reader sheet has no guest login CTA' do
      render_inline(ParagraphReportSheetComponent.new(chapter: @chapter, user: @reader))

      assert_selector '[data-paragraph-report-chip-label-value]'
      assert_no_link 'Увійдіть, щоб повідомити про помилку'
    end

    test 'a guest gets a login link back to the chapter' do
      render_inline(ParagraphReportSheetComponent.new(chapter: @chapter, user: nil))

      assert_selector '#paragraph-report[data-controller=paragraph-report]'
      assert_link 'Увійдіть, щоб повідомити про помилку',
                  href: /return_to=.*#{@chapter.slug}/
      assert_no_selector 'form[data-paragraph-report-target=form]'
    end

    test 'a guest can still copy from the sheet' do
      render_inline(ParagraphReportSheetComponent.new(chapter: @chapter, user: nil))

      assert_selector '[data-paragraph-report-chip-label-value]'
      assert_button 'Копіювати абзац'
    end

    test 'the team sees the report sheet like any reader' do
      render_inline(ParagraphReportSheetComponent.new(chapter: @chapter, user: users(:user_one)))

      assert_selector '#paragraph-report form[data-paragraph-report-target=form]'
      assert_selector '[data-paragraph-report-chip-label-value]'
      assert_button 'Копіювати абзац'
    end

    test 'stimulus values point at the create endpoint' do
      render_inline(ParagraphReportSheetComponent.new(chapter: @chapter, user: @reader))

      assert_selector '[data-paragraph-report-url-value*="paragraph_reports"]'
      assert_selector '[data-paragraph-report-guest-value=false]'
      assert_selector '[data-paragraph-report-success-value]'
    end

    test 'stimulus values include copy and chip labels' do
      render_inline(ParagraphReportSheetComponent.new(chapter: @chapter, user: @reader))

      assert_selector '[data-paragraph-report-copied-value]'
      assert_selector '[data-paragraph-report-copy-failed-value]'
      assert_selector '[data-paragraph-report-chip-label-value]'
    end
  end
end
