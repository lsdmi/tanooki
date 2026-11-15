# frozen_string_literal: true

module Chapters
  # Bottom sheet for a translation-error report: desktop context menu, or select text → «Повідомити» chip.
  # Also offers «Копіювати абзац». Same UI for readers, team, and admins; guests get a login CTA.
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
      {
        controller: 'paragraph-report',
        paragraph_report_url_value: chapter_paragraph_reports_path(chapter),
        paragraph_report_guest_value: guest?,
        paragraph_report_login_path_value: login_path,
        paragraph_report_reporter_name_value: user&.name.to_s,
        paragraph_report_message_max_value: MESSAGE_MAX
      }.merge(stimulus_copy_data, stimulus_flash_data)
    end

    def stimulus_copy_data
      {
        paragraph_report_copied_value: t('chapters.paragraph_reports.copied'),
        paragraph_report_copy_failed_value: t('chapters.paragraph_reports.copy_failed'),
        paragraph_report_chip_label_value: t('chapters.paragraph_reports.chip')
      }
    end

    def stimulus_flash_data
      {
        paragraph_report_success_value: t('chapters.paragraph_reports.success'),
        paragraph_report_error_value: t('chapters.paragraph_reports.errors.generic')
      }
    end
  end
end
