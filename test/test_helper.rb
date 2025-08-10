# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails'

SimpleCov.start do
  add_filter 'app/mailers/application_mailer.rb'
  add_filter 'app/models/application_record.rb'
  add_filter 'app/models/user.rb'
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/autorun'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |_worker|
      SimpleCov.result
    end

    set_fixture_class action_text_rich_texts: ActionText::RichText

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

# Helper method for authenticating users in tests
module AuthenticationTestHelper
  def sign_in(user)
    session_record = user.sessions.create!(
      user_agent: 'Test User Agent',
      ip_address: '127.0.0.1'
    )

    # In tests, we need to set the cookie directly since signed cookies aren't available
    cookies[:session_id] = session_record.id
    Current.session = session_record
  end

  def sign_out
    cookies.delete(:session_id)
    Current.session = nil
  end
end

# Include the helper in ActionDispatch::IntegrationTest
class ActionDispatch::IntegrationTest
  include AuthenticationTestHelper
end
