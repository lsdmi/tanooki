# frozen_string_literal: true

# Reader reports a translation error on one chapter paragraph block. JSON for the reader UI (P1).
class ChapterParagraphReportsController < ApplicationController
  ERROR_STATUSES = {
    own_work: :forbidden,
    not_released: :unprocessable_content,
    blank_quote: :unprocessable_content,
    duplicate_open: :unprocessable_content,
    message_too_long: :unprocessable_content,
    invalid_anchor: :unprocessable_content
  }.freeze

  before_action :authenticate_user!
  rate_limit to: 20, within: 1.minute, by: -> { current_user.id }, only: :create

  def create
    result = Chapters::CreateParagraphReport.call(chapter:, user: current_user, attrs: report_attrs)
    return render_error(result.error) unless result.ok

    render json: report_json(result.report), status: :created
  end

  private

  def chapter = Chapter.friendly.find(params.expect(:chapter_id))

  def report_attrs = params.permit(:block_index, :quote, :digest, :message).to_h.symbolize_keys

  def report_json(report)
    { id: report.id, status: report.status, block_index: report.block_index, quote: report.quote }
  end

  def render_error(error)
    render json: { error: t("chapters.paragraph_reports.errors.#{error}") }, status: ERROR_STATUSES.fetch(error)
  end
end
