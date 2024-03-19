# frozen_string_literal: true

require 'test_helper'

class FictionListsControllerTest < ActionDispatch::IntegrationTest
  test 'should get alphabetical' do
    get alphabetical_fictions_url
    assert_response :success
    assert_template :alphabetical
  end
end
