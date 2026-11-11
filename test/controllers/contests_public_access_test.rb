# frozen_string_literal: true

require 'test_helper'

class ContestsPublicAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'contests index route is removed' do
    get '/contests'

    assert_response :not_found
  end

  test 'non-allowlisted show is hidden from guests while unlisted' do
    get contest_path(contests(:submissions))

    assert_response :not_found
  end

  test 'allowlisted archive show is public while unlisted' do
    get contest_path(contests(:results))

    assert_response :success
    assert_select '#results'
  end

  test 'non-admin cannot open non-allowlisted show while unlisted' do
    sign_in users(:user_two)

    get contest_path(contests(:submissions))

    assert_response :not_found
  end

  test 'non-admin can open allowlisted archive show while unlisted' do
    sign_in users(:user_two)

    get contest_path(contests(:results))

    assert_response :success
    assert_select '#results'
  end

  test 'when listed, guests can open any visible contest show' do
    with_contests_listed do
      get contest_path(contests(:submissions))

      assert_response :success
      assert_select '#hero'
    end
  end
end
