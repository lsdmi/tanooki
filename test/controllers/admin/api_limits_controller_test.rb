# frozen_string_literal: true

require 'test_helper'

module Admin
  class ApiLimitsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup { @member = users(:user_two) }

    teardown do
      Rails.cache.delete(Api::Limits.counter_key(:published_edit_hour, @member, Api::Limits::PublishedEdits.hour_period))
    end

    test 'an admin sees how many published edits a member has left' do
      sign_in users(:user_one)
      ApiToken.issue!(user: @member, name: 'Chat', scopes: %w[chapters:read chapters:write])
      Api::Limits::PublishedEdits.charge!(@member)

      get admin_api_limits_url

      assert_response :success
      assert_select 'h2', text: @member.name
      assert_select 'li', text: /1 з 60/
    end

    test 'a member cannot open the limits page' do
      sign_in @member

      get admin_api_limits_url

      assert_redirected_to root_path
    end
  end
end
