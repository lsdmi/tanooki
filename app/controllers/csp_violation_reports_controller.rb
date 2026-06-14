# frozen_string_literal: true

# Receives browser CSP violation reports (report-only policy in production).
class CspViolationReportsController < ActionController::API
  def create
    report = parse_report
    log_report(report) if report.present?

    head :no_content
  end

  private

  def parse_report
    body = request.raw_post
    return if body.blank?

    payload = JSON.parse(body)
    payload['csp-report'] || payload.dig(0, 'body') || payload
  rescue JSON::ParserError
    Rails.logger.warn("[CSP] invalid report payload: #{body.truncate(500)}")
    nil
  end

  def log_report(report)
    Rails.logger.warn("[CSP] #{report_summary(report).to_json}")
  end

  def report_summary(report)
    %w[
      document-uri blocked-uri violated-directive effective-directive
      original-policy source-file line-number column-number disposition
    ].index_with { |key| report[key] }.compact
  end
end
