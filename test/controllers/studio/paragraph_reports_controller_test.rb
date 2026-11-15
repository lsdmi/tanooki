# frozen_string_literal: true

require 'test_helper'

module Studio
  class ParagraphReportsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @report = ParagraphReport.create!(
        user: users(:user_two),
        chapter: chapters(:one),
        block_index: 0,
        quote: 'Помилка в тексті',
        digest: 'e' * ParagraphReport::DIGEST_LENGTH
      )
      sign_in users(:user_one)
    end

    test 'fixes a report and returns to the studio tab' do
      patch studio_paragraph_report_path(@report, status: 'fixed')

      assert_redirected_to studio_index_path(tab: 'notifications')
      assert_predicate @report.reload, :fixed?
    end

    test 'dismisses a report' do
      patch studio_paragraph_report_path(@report, status: 'dismissed')

      assert_redirected_to studio_index_path(tab: 'notifications')
      assert_predicate @report.reload, :dismissed?
    end

    test 'forbids a user who does not manage the chapter' do
      sign_in users(:user_two)

      patch studio_paragraph_report_path(@report, status: 'fixed')

      assert_redirected_to studio_index_path(tab: 'notifications')
      assert_predicate @report.reload, :open?
    end

    test 'requires authentication' do
      sign_out users(:user_one)

      patch studio_paragraph_report_path(@report, status: 'fixed')

      assert_response :redirect
      assert_predicate @report.reload, :open?
    end

    test 'fixes every report id in a dedup group' do
      twin = ParagraphReport.create!(
        user: users('user_101'),
        chapter: chapters(:one),
        block_index: 0,
        quote: 'Помилка в тексті',
        digest: @report.digest,
        message: 'теж бачу'
      )

      patch studio_paragraph_report_path(@report, status: 'fixed'), params: { ids: [@report.id, twin.id] }

      assert_redirected_to studio_index_path(tab: 'notifications')
      assert_predicate @report.reload, :fixed?
      assert_predicate twin.reload, :fixed?
    end
  end
end
