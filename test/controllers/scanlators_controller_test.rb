# frozen_string_literal: true

require 'test_helper'

class ScanlatorsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index as admin' do
    sign_in users(:user_one)
    get scanlators_path
    assert_response :success
    assert_template 'users/show'
  end

  test 'should get index as non-admin user' do
    sign_in users(:user_two)
    get scanlators_path
    assert_response :success
    assert_template 'users/show'
  end

  test 'should get new' do
    sign_in users(:user_one)
    get new_scanlator_url
    assert_response :success
  end

  test 'should create scanlator' do
    sign_in users(:user_one)
    assert_difference('Scanlator.count') do
      post scanlators_url, params: {
        scanlator: {
          avatar: Rack::Test::UploadedFile.new(Rails.root.join('app', 'assets', 'images', 'logo.svg'), 'image/svg'),
          banner: Rack::Test::UploadedFile.new(Rails.root.join('app', 'assets', 'images', 'logo.svg'), 'image/svg'),
          member_ids: [users(:user_one).id],
          title: 'New Scanlator'
        }
      }
    end

    assert_redirected_to scanlator_path(Scanlator.last)
  end
end
