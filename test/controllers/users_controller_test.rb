# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @avatar_id = 1
    @user = users(:user_one)
  end

  test 'should get show' do
    sign_in @user

    get :blogs
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:fictions_size)
  end

  test "should update user's avatar" do
    sign_in @user

    put :update, params: { id: @user.id, user: { avatar_id: @avatar_id, name: 'John Doe' } }

    @user.reload
    assert_equal @avatar_id, @user.avatar_id

    assert_response :redirect
    assert_equal 'Профіль оновлено.', flash[:notice]
  end

  test 'update fails with invalid user params' do
    sign_in @user

    put :update, params: { id: @user.id, user: { avatar_id: @avatar_id, name: '' } }, format: :turbo_stream

    assert_template 'users/dashboard/_avatars'
    assert_response :success
  end

  test 'should get avatars' do
    sign_in @user
    get :avatars
    assert_response :success
    assert_template 'users/dashboard/_avatars'
    assert_not_nil assigns(:avatars)
  end

  test 'should get blogs' do
    sign_in @user
    get :blogs
    assert_response :success
    assert_template 'users/dashboard/_blogs'
    assert_not_nil assigns(:pagy)
    assert_not_nil assigns(:publications)
  end

  test 'should get readings' do
    sign_in @user
    get :readings
    assert_response :success
    assert_template 'users/dashboard/_readings'
    assert_not_nil assigns(:pagy)
    assert_not_nil assigns(:fictions)
    assert_not_nil assigns(:paginators)
  end
end
