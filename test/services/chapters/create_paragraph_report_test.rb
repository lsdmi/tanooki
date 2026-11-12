# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CreateParagraphReportTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @user = users(:user_two)
      @digest = 'b' * ParagraphReport::DIGEST_LENGTH
    end

    test 'creates an open report with a normalized quote' do
      result = CreateParagraphReport.call(
        chapter: @chapter, user: @user,
        attrs: { block_index: 2, quote: "  багато   пробілів\nі рядок  ", digest: @digest, message: ' краще так ' }
      )

      assert_equal(
        [true, true, 2, 'багато пробілів і рядок', 'краще так', @digest],
        [result.ok, result.report.open?, result.report.block_index, result.report.quote, result.report.message,
         result.report.digest]
      )
    end

    test 'the team cannot report its own chapter' do
      ScanlatorUser.create!(scanlator: scanlators(:one), user: @user)

      assert_no_difference('ParagraphReport.count') do
        assert_equal :own_work, call_report.error
      end
    end

    test 'an admin cannot report either' do
      assert_equal :own_work, call_report(user: users(:user_one)).error
    end

    test 'a draft or scheduled chapter cannot be reported' do
      @chapter.update!(status: 'draft')

      assert_equal :not_released, call_report.error

      @chapter.update!(status: 'published', published_at: 1.day.from_now)

      assert_equal :not_released, call_report.error
    end

    test 'blank quote and bad anchors are rejected' do
      assert_equal :blank_quote, call_report(quote: '   ').error
      assert_equal :invalid_anchor, call_report(block_index: -1).error
      assert_equal :invalid_anchor, call_report(digest: 'nope').error
    end

    test 'duplicate open reports are rejected' do
      assert call_report.ok

      assert_no_difference('ParagraphReport.count') do
        assert_equal :duplicate_open, call_report.error
      end
    end

    test 'an oversize message is rejected' do
      assert_equal :message_too_long, call_report(message: 'м' * (ParagraphReport::MESSAGE_MAX + 1)).error
    end

    test 'a long quote is sliced to the max length' do
      result = call_report(quote: 'я' * (ParagraphReport::QUOTE_MAX + 20))

      assert result.ok
      assert_equal ParagraphReport::QUOTE_MAX, result.report.quote.length
    end

    private

    def call_report(user: @user, **overrides)
      CreateParagraphReport.call(
        chapter: @chapter, user:,
        attrs: { block_index: 0, quote: 'Текст абзацу', digest: @digest, message: nil, **overrides }
      )
    end
  end
end
