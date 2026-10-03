# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails'

SimpleCov.start do
  add_filter 'app/mailers/application_mailer.rb'
  add_filter 'app/models/application_record.rb'
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'propshaft_dev_manifest'

PropshaftDevManifest.refresh!(Rails.application.config.assets.manifest_path) if Rails.env.test?

require 'rails/test_help'
require 'minitest/autorun'
require 'minitest/mock'
require 'view_component/test_helpers'

# Routes load lazily on the first request. Draw them now, before workers fork: a test that stubs Rails.env to
# development around its first request would otherwise draw them with the Lookbook mount, which fails under test and
# breaks every later test in that worker.
Rails.application.reload_routes_unless_loaded

Rails.root.glob('test/test_helpers/**/*.rb').each { |path| require path }

module ActiveSupport
  class TestCase
    include CoverUploadHelper
    include ChapterImageHelper

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
