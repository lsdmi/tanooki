# frozen_string_literal: true

require 'test_helper'

class FictionsControllerCommentsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'show defers comments in lazy turbo frame' do
    get fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_comments[loading="lazy"][src=?]', comments_fiction_path(@fiction)
    assert_select 'turbo-frame#comments', count: 0
    assert_select 'turbo-frame#new_comment', count: 0
  end

  test 'comments frame renders list and form for signed-in user' do
    get comments_fiction_url(@fiction)

    assert_response :success
    assert_select 'turbo-frame#fiction_comments turbo-frame#comments'
    assert_select 'turbo-frame#new_comment'
  end

  test 'comments frame renders list for guest when fiction has comments' do
    sign_out :user

    get comments_fiction_url(fictions(:two))

    assert_response :success
    assert_select 'turbo-frame#fiction_comments turbo-frame#comments'
    assert_select 'turbo-frame#new_comment', count: 0
  end

  test 'comments frame shows guest login prompt when fiction has no comments' do
    sign_out :user

    get comments_fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_comments'
    assert_includes response.body, 'Увійти, аби лишити коментар!'
    assert_select 'turbo-frame#comments', count: 0
  end
end
