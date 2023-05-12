# frozen_string_literal: true

require 'test_helper'

module Admin
  class FictionsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @fiction = fictions(:one)
      sign_in users(:user_one)
    end

    test 'should get index' do
      get admin_fictions_url
      assert_response :success
    end

    test 'should get new' do
      get new_admin_fiction_url
      assert_response :success
    end

    test 'should create fiction' do
      assert_difference('Fiction.count') do
        post admin_fictions_url, params: {
          fiction: {
            title: 'New Fiction',
            author: 'New Author',
            description: 'a' * 50,
            cover: Rack::Test::UploadedFile.new(
              Rails.root.join('app', 'assets', 'images', 'logo.svg'),
              'image/svg'
            ),
            status: :announced,
            user_id: @fiction.user_id
          }
        }
      end

      assert_redirected_to root_path
    end

    test 'should not create fiction with invalid params' do
      assert_no_difference('Fiction.count') do
        post admin_fictions_url, params: { fiction: { title: '', author: '', user_id: @fiction.user_id } }
      end

      assert_response :unprocessable_entity
    end

    test 'should get edit' do
      get edit_admin_fiction_url(@fiction)
      assert_response :success
    end

    test 'should update fiction' do
      patch admin_fiction_url(@fiction), params: {
        fiction: {
          cover: Rack::Test::UploadedFile.new(
            Rails.root.join('app', 'assets', 'images', 'logo.svg'),
            'image/svg'
          ),
          title: 'Updated Title'
        }
      }
      assert_redirected_to root_path
      @fiction.reload
      assert_equal 'Updated Title', @fiction.title
    end

    test 'should not update fiction with invalid params' do
      patch admin_fiction_url(@fiction), params: { fiction: { title: '' } }
      assert_response :unprocessable_entity
      @fiction.reload
      assert_not_equal '', @fiction.title
    end

    test 'should destroy fiction' do
      assert_difference('Fiction.count', -1) do
        delete admin_fiction_url(@fiction)
      end

      assert_response :success
    end
  end
end
