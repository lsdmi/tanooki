# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ResolveParagraphReportsTest < ActiveSupport::TestCase
    setup do
      @digest = 'd' * ParagraphReport::DIGEST_LENGTH
      @reports = [
        ParagraphReport.create!(
          user: users(:user_two), chapter: chapters(:one), block_index: 1,
          quote: 'Текст із помилкою', digest: @digest
        ),
        ParagraphReport.create!(
          user: users('user_101'), chapter: chapters(:one), block_index: 1,
          quote: 'Текст із помилкою', digest: @digest, message: 'калька'
        )
      ]
      @resolver = users(:user_one)
    end

    test 'fixes every report in the group' do
      result = ResolveParagraphReports.call(reports: @reports, user: @resolver, status: 'fixed')

      assert result.ok
      assert_equal 2, result.reports.size
      assert(@reports.all? { |report| report.reload.fixed? })
    end

    test 'stops when the actor cannot manage the chapter' do
      result = ResolveParagraphReports.call(reports: @reports, user: users(:user_two), status: 'fixed')

      assert_equal :forbidden, result.error
      assert(@reports.all? { |report| report.reload.open? })
    end
  end
end
