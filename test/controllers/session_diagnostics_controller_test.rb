# frozen_string_literal: true

require 'test_helper'

class SessionDiagnosticsControllerTest < ActionDispatch::IntegrationTest
  test 'create logs client report and returns no content' do
    log_io = StringIO.new
    logger = ActiveSupport::Logger.new(log_io)

    Rails.stub(:logger, logger) do
      post session_diagnostics_path,
           params: {
             reason: 'session_lost_on_protected_page',
             page_url: 'https://baka.in.ua/studio'
           }
    end

    assert_response :no_content
    assert_match(/\[SessionDiagnostics\].*"event":"client_report"/, log_io.string)
  end

  test 'studio auth failure logs session diagnostics' do
    log_io = StringIO.new
    logger = ActiveSupport::Logger.new(log_io)

    Rails.stub(:logger, logger) do
      get studio_index_path
    end

    assert_redirected_to new_user_session_path
    assert_match(/\[SessionDiagnostics\].*"event":"auth_failure"/, log_io.string)
  end
end
