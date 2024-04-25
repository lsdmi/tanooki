# frozen_string_literal: true

require 'test_helper'

class AvatarsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    sign_in @user
  end

  test 'should redirect to root path if user is not an admin' do
    sign_in users(:user_two)
    get admin_avatars_path
    assert_redirected_to root_path
  end

  test 'should get index' do
    get admin_avatars_path
    assert_response :success
  end

  test 'should create avatar' do
    avatar_image = Rack::Test::UploadedFile.new(
      Rails.root.join('app', 'assets', 'images', 'logo-default.svg'),
      'image/svg'
    )
    assert_difference('Avatar.count') do
      post admin_avatars_url, params: { avatar: { image: avatar_image } }, xhr: true
    end
    assert_response :success
  end

  test 'should destroy avatar' do
    avatar = avatars(:one)
    assert_difference('Avatar.count', -1) do
      delete admin_avatar_path(avatar), headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
    end
    assert_response :success
  end
end
