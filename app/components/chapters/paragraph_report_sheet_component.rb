# frozen_string_literal: true

module Chapters
  # Bottom sheet for a translation-error report: select text → «Повідомити».
  # Same UI for readers, team, and admins; guests get a login CTA.
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

      chapter.public_visible?
    end

    private

    attr_reader :chapter, :user

    def guest? = user.nil?

    def login_path
      new_user_session_path(return_to: chapter_path(chapter, anchor: 'user-content'))
    end

    def stimulus_data
      { controller: 'paragraph-report' }.merge(stimulus_endpoint_data, stimulus_label_data)
    end

    def stimulus_endpoint_data
      {
        paragraph_report_url_value: chapter_paragraph_reports_path(chapter),
        paragraph_report_guest_value: guest?,
        paragraph_report_reporter_name_value: user&.name.to_s,
        paragraph_report_message_max_value: MESSAGE_MAX
      }
    end

    def stimulus_label_data
      {
        paragraph_report_chip_label_value: t('chapters.paragraph_reports.chip'),
        paragraph_report_success_value: t('chapters.paragraph_reports.success'),
        paragraph_report_error_value: t('chapters.paragraph_reports.errors.generic')
      }
    end
  end
end
