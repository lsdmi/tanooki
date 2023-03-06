# frozen_string_literal: true

require 'test_helper'

class TalesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @tale = publications(:tale_approved_one)
  end

  test 'should get show' do
    get tale_url(@tale)
    assert_response :success
  end
end
