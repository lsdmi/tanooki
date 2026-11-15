# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ResolveParagraphReportTest < ActiveSupport::TestCase
    setup do
      @report = ParagraphReport.create!(
        user: users(:user_two),
        chapter: chapters(:one),
        block_index: 1,
        quote: 'Текст із помилкою',
        digest: 'd' * ParagraphReport::DIGEST_LENGTH
      )
      @resolver = users(:user_one)
    end

    test 'fixes an open report' do
      result = ResolveParagraphReport.call(report: @report, user: @resolver, status: 'fixed')

      assert result.ok
      assert_equal [true, @resolver], [result.report.fixed?, result.report.resolved_by]
      assert_not_nil result.report.resolved_at
    end

    test 'dismisses an open report' do
      result = ResolveParagraphReport.call(report: @report, user: @resolver, status: 'dismissed')

      assert result.ok
      assert_predicate result.report, :dismissed?
    end

    test 'rejects a foreign team member' do
      result = ResolveParagraphReport.call(report: @report, user: users(:user_two), status: 'fixed')

      assert_equal :forbidden, result.error
      assert_predicate @report.reload, :open?
    end

    test 'rejects a second resolve' do
      ResolveParagraphReport.call(report: @report, user: @resolver, status: 'fixed')

      result = ResolveParagraphReport.call(report: @report.reload, user: @resolver, status: 'dismissed')

      assert_equal :already_resolved, result.error
    end

    test 'rejects an unknown status' do
      assert_equal :invalid_transition,
                   ResolveParagraphReport.call(report: @report, user: @resolver, status: 'open').error
    end
  end
end
