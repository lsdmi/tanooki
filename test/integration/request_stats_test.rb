# frozen_string_literal: true

require 'test_helper'

class RequestStatsIntegrationTest < ActionDispatch::IntegrationTest
  test 'records the action, status, SQL, view time and response size of a real request' do
    stats = Analytics::RequestStats.new(background: false)
    fiction = fictions(:one)

    ActiveSupport::Notifications.subscribed(stats.method(:add_event), 'process_action.action_controller') do
      get fiction_path(fiction)
    end
    stats.flush

    row = RequestStat.find_by!(endpoint: 'FictionsController#show')

    assert_equal [1, 0, response.body.bytesize], row.values_at(:requests, :server_errors, :bytes_sum)
    assert_operator row.queries_sum, :>, 0
    assert_operator row.view_ms_sum, :>, 0
  end
end
