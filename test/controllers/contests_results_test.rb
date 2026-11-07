# frozen_string_literal: true

require 'test_helper'

class ContestsResultsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'results are ranked cover cards' do
    get contest_path(contests(:results))

    assert_response :success
    assert_select '#results article', text: /Старий переможець/
    assert_select '#results article', text: /Автор 2024/
  end
end
