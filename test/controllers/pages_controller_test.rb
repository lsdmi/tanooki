# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'should get rules' do
    get rules_url

    assert_response :success
  end

  test 'should get privacy' do
    get privacy_url

    assert_response :success
  end
end
