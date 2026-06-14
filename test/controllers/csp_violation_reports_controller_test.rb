# frozen_string_literal: true

require 'test_helper'

class CspViolationReportsControllerTest < ActionDispatch::IntegrationTest
  test 'POST csp-violation-report logs summary and returns no content' do
    report = {
      'csp-report' => {
        'document-uri' => 'https://baka.in.ua/fictions',
        'violated-directive' => 'script-src',
        'blocked-uri' => 'inline',
        'source-file' => 'https://baka.in.ua/fictions',
        'line-number' => 42
      }
    }
    log_io = StringIO.new
    logger = ActiveSupport::Logger.new(log_io)

    Rails.stub(:logger, logger) do
      post '/csp-violation-report',
           params: report.to_json,
           headers: { 'CONTENT_TYPE' => 'application/csp-report' }
    end

    assert_response :no_content
    assert_match(%r{\[CSP\].*script-src.*baka\.in\.ua/fictions}m, log_io.string)
  end

  test 'POST csp-violation-report accepts invalid JSON without error' do
    post '/csp-violation-report',
         params: 'not-json',
         headers: { 'CONTENT_TYPE' => 'application/csp-report' }

    assert_response :no_content
  end
end
