# frozen_string_literal: true

module Chapters
  # Bottom sheet for reporting a translation error on a reader block (long-press / context menu).
  # Guests get a login CTA; the chapter team does not see this UI at all.
  class ParagraphReportSheetComponent < ViewComponent::Base
    MESSAGE_MAX = ParagraphReport::MESSAGE_MAX

    def initialize(chapter:, user:)
      super()
      @chapter = chapter
      @user = user
    end

    def render?
      return false if chapter.license_hidden?
      return true if guest?

      !owner? && chapter.public_visible?
    end

    private

    attr_reader :chapter, :user

    def guest? = user.nil?

    def owner? = user&.manages_chapter?(chapter)

    def login_path
      new_user_session_path(return_to: chapter_path(chapter, anchor: 'user-content'))
    end

    def stimulus_data
      {
        controller: 'paragraph-report',
        paragraph_report_url_value: chapter_paragraph_reports_path(chapter),
        paragraph_report_guest_value: guest?,
        paragraph_report_login_path_value: login_path,
        paragraph_report_success_value: t('chapters.paragraph_reports.success'),
        paragraph_report_error_value: t('chapters.paragraph_reports.errors.generic'),
        paragraph_report_reporter_name_value: user&.name.to_s,
        paragraph_report_message_max_value: MESSAGE_MAX
      }
    end
  end
end
