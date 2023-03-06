# frozen_string_literal: true

require 'test_helper'

class AdvertisementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    user = users(:user_one)
    host! 'localhost:3000'
    sign_in user
    @ads_params = {
      caption: Faker::Lorem.sentence,
      description: 'test',
      cover: Rack::Test::UploadedFile.new(
        Rails.root.join('app', 'assets', 'images', 'logo.svg'),
        'image/svg'
      ),
      resource: 'test',
      enabled: true
    }
  end

  test 'should get index' do
    get admin_advertisements_url
    assert_response :success
  end

  test 'should get new' do
    get new_admin_advertisement_url
    assert_response :success
  end

  test 'should create advertisement' do
    assert_difference('Advertisement.count') do
      post admin_advertisements_url, params: { advertisement: @ads_params }
    end

    assert_redirected_to root_path
  end

  test 'should get edit' do
    get edit_admin_advertisement_url(Advertisement.first)
    assert_response :success
  end

  test 'should update advertisement' do
    patch admin_advertisement_url(Advertisement.first), params: { advertisement: @ads_params }
    assert_redirected_to root_path
  end
end
