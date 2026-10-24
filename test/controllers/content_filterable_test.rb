# frozen_string_literal: true

require 'test_helper'

class ContentFilterableTest < ActionDispatch::IntegrationTest
  test 'a page that does not ask for the filter does not read it' do
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == 'SCHEMA' }

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      get root_path
    end

    assert_predicate queries, :any?
    assert(queries.none? { |sql| sql.match?(/user_content_filters|user_hidden_packages/) })
  end
end
