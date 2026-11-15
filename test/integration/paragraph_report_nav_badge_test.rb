# frozen_string_literal: true

require 'test_helper'

# Nav «Сповіщення» badge for unseen open paragraph-error reports.
class ParagraphReportNavBadgeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'notification badge shows when open paragraph reports await the team' do
    user = users(:user_one)
    mark_comment_inbox_read!(user)
    create_open_paragraph_report!
    sign_in user

    get notification_badge_path

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge svg.text-status-danger-solid'
  end

  test 'visiting notifications clears the paragraph-report badge' do
    user = users(:user_one)
    mark_comment_inbox_read!(user)
    create_open_paragraph_report!
    sign_in user

    get notifications_path
    follow_redirect! if response.redirect?
    get notification_badge_path

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge svg', count: 0
  end

  test 'a newer open report brings the badge back after Studio' do
    user = users(:user_one)
    mark_comment_inbox_read!(user)
    create_open_paragraph_report!
    sign_in user

    get notifications_path
    follow_redirect! if response.redirect?
    create_open_paragraph_report!(quote: 'Новий фрагмент', block_index: 1)
    get notification_badge_path

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge svg.text-status-danger-solid'
  end

  test 'notification badge stays empty for readers without paragraph-report access' do
    user = users(:user_two)
    mark_comment_inbox_read!(user)
    create_open_paragraph_report!(user: users(:user_one))
    sign_in user

    get notification_badge_path

    assert_response :success
    assert_select 'turbo-frame#nav-notification-badge svg', count: 0
  end

  private

  def mark_comment_inbox_read!(user)
    latest = Comments::InboxCollector.new(user).call.first
    user.update!(latest_read_comment_id: latest&.id)
  end

  def create_open_paragraph_report!(user: users(:user_two), quote: 'Фрагмент', block_index: 0)
    ParagraphReport.create!(
      user:,
      chapter: chapters(:one),
      block_index:,
      quote:,
      digest: 'c' * ParagraphReport::DIGEST_LENGTH,
      message: 'опечатка'
    )
  end
end
