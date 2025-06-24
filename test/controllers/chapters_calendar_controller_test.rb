# frozen_string_literal: true

require 'test_helper'

class ChaptersCalendarControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get calendar_fictions_path
    assert_response :success
  end
end
