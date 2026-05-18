# frozen_string_literal: true

require 'test_helper'

class AdultContentAcknowledgementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'create sets session flag for guests' do
    post adult_content_acknowledge_url

    assert_response :no_content
    assert session[:adult_content_ack]
  end

  test 'signed-in user starts without adult content acknowledgement date' do
    assert_nil users(:user_one).adult_content_acknowledged_at
  end

  test 'create sets user date when signed in' do
    user = users(:user_one)
    sign_in user
    post adult_content_acknowledge_url

    assert_response :no_content
    assert_not session[:adult_content_ack]
    assert_equal Time.zone.today, user.reload.adult_content_acknowledged_at
  end
end
