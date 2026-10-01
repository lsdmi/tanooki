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
