# frozen_string_literal: true

require 'test_helper'

class FictionListsControllerTest < ActionDispatch::IntegrationTest
  test 'should get alphabetical' do
    get alphabetical_fictions_url
    assert_response :success
    assert_template :alphabetical
  end

  test 'should get alphabetical with only_finished param' do
    get alphabetical_fictions_url, params: { only_finished: 'on' }
    assert_response :success
    assert_template :alphabetical
  end

  test "should respond with turbo stream format" do
    get alphabetical_fictions_url(format: :turbo_stream)
    assert_response :success
    assert_match(/turbo-stream/, @response.media_type)
  end
end
