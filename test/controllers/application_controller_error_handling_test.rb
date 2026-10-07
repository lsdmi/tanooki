# frozen_string_literal: true

require 'test_helper'

class ApplicationControllerErrorHandlingTest < ActionDispatch::IntegrationTest
  test 'a missing record is a 404 in production, not caught by the catch-all error handler' do
    in_production { get fiction_url('no-such-fiction') }

    assert_response :not_found
  end

  test 'other errors render the error page with a 500 in production' do
    Fiction.stub(:includes, ->(*) { raise ArgumentError, 'boom' }) do
      in_production { get fiction_url(fictions(:one)) }
    end

    assert_response :internal_server_error
  end

  test 'a rate limit hit is a 429, not caught by the catch-all error handler' do
    Fiction.stub(:includes, ->(*) { raise ActionController::TooManyRequests }) do
      in_production { get fiction_url(fictions(:one)) }
    end

    assert_response :too_many_requests
    assert_equal I18n.t('errors.too_many_requests'), response.body
  end

  test 'errors in non-HTML requests are a bare 500 rather than a missing template' do
    Fiction.stub(:includes, ->(*) { raise ArgumentError, 'boom' }) do
      in_production { get fiction_url(fictions(:one)), headers: { 'Accept' => 'application/json' } }
    end

    assert_response :internal_server_error
    assert_empty response.body
  end

  test 'the handled error is left on the request for request stats' do
    stats = Analytics::RequestStats.new(background: false)
    Fiction.stub(:includes, ->(*) { raise ArgumentError, 'boom' }) do
      ActiveSupport::Notifications.subscribed(stats.method(:add_event), 'process_action.action_controller') do
        in_production { get fiction_url(fictions(:one)) }
      end
    end
    stats.flush

    sample = RequestStat.find_by!(endpoint: 'FictionsController#show').error_sample

    assert sample.start_with?('ArgumentError: boom at test/controllers/application_controller_error_handling_test.rb:')
    assert sample.end_with?('(GET /fictions/one)')
  end

  test 'errors still raise outside production' do
    Fiction.stub(:includes, ->(*) { raise ArgumentError, 'boom' }) do
      assert_raises(ArgumentError) { get fiction_url(fictions(:one)) }
    end
  end

  private

  def in_production(&)
    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new('production'), &)
  end
end
