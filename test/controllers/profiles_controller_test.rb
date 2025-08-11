# frozen_string_literal: true

require 'test_helper'

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @sqid = Sqids.new.encode([@user.id])
  end

  test 'should get show with valid user' do
    get "/profile/#{@sqid}"
    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal @user, assigns(:user)
  end

  test 'should redirect to root with invalid user' do
    get '/profile/invalid_sqid'
    assert_response :redirect
    assert_redirected_to root_path
  end

  test 'should set user instance variable' do
    get "/profile/#{@sqid}"
    assert_equal @user, assigns(:user)
  end
end
