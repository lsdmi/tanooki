# frozen_string_literal: true

require 'test_helper'

class ContestsPublicAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'index is hidden from guests while contests are unlisted' do
    get contests_path

    assert_response :not_found
  end

  test 'non-allowlisted show is hidden from guests while hub is unlisted' do
    get contest_path(contests(:submissions))

    assert_response :not_found
  end

  test 'allowlisted archive show is public while hub is unlisted' do
    get contest_path(contests(:results))

    assert_response :success
    assert_select '#results'
  end

  test 'non-admin cannot open hub or non-allowlisted show while unlisted' do
    sign_in users(:user_two)

    get contests_path

    assert_response :not_found

    get contest_path(contests(:submissions))

    assert_response :not_found
  end

  test 'non-admin can open allowlisted archive show while hub is unlisted' do
    sign_in users(:user_two)

    get contest_path(contests(:results))

    assert_response :success
    assert_select '#results'
  end

  test 'when listed, guests can open the hub' do
    with_contests_listed do
      get contests_path

      assert_response :success
      assert_select '.contests-page'
    end
  end
end
