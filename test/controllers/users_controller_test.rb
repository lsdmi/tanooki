# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @avatar_id = 1
    @user = users(:user_one)
  end

  test 'should get show' do
    sign_in @user

    get blogs_path
    assert_response :redirect
    assert_redirected_to studio_index_path
  end

  test "should update user's avatar" do
    sign_in @user

    put user_path(@user), params: { user: { avatar_id: @avatar_id, name: 'John Doe' } }

    @user.reload
    assert_equal @avatar_id, @user.avatar_id

    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type
  end

  test 'should get avatars' do
    sign_in @user
    get avatars_path
    assert_response :redirect
    assert_redirected_to studio_index_path
  end

  test 'should get blogs' do
    sign_in @user
    get blogs_path
    assert_response :redirect
    assert_redirected_to studio_index_path
  end

  test 'should get readings' do
    sign_in @user
    get readings_path
    assert_response :redirect
    assert_redirected_to studio_index_path
  end

  test 'should get pokemons' do
    sign_in @user
    get pokemons_path
    assert_response :redirect
    assert_redirected_to studio_index_path
  end
end
