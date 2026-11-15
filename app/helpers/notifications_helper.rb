# frozen_string_literal: true

# Navbar «Сповіщення» chrome: unread comments and unseen paragraph-error reports.
module NotificationsHelper
  def show_nav_notification_badge?
    show_comment_status? || nav_paragraph_reports_pending?
  end

  def nav_paragraph_reports_pending?
    return false unless current_user
    return false unless Studio::ParagraphReportsAccess.allowed?(current_user)

    latest_id = ParagraphReports::InboxCollector.new(current_user).latest_open_id
    return false unless latest_id

    current_user.latest_read_paragraph_report_id != latest_id
  end
end
