# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails'

SimpleCov.start do
  add_filter 'app/mailers/application_mailer.rb'
  add_filter 'app/models/application_record.rb'
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/autorun'
require 'minitest/mock'
require 'view_component/test_helpers'

Rails.root.glob('test/test_helpers/**/*.rb').each { |path| require path }

module ActiveSupport
  class TestCase
    include CoverUploadHelper

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

    setup do
      Rails.cache.clear
    end
  end
end

class ViewComponentTestCase < ViewComponent::TestCase
  include Devise::Test::IntegrationHelpers if defined?(Devise)
end

module ActionDispatch
  class IntegrationTest
    include CoverUploadHelper
  end
end
