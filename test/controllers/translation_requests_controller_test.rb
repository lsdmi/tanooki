# frozen_string_literal: true

require 'test_helper'

class TranslationRequestsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @scanlator = scanlators(:one)
    @translation_request = translation_requests(:one)
    # ScanlatorUser association already exists in fixtures
  end

  test 'should get index' do
    get translation_requests_url
    assert_response :success
  end

  test 'should get index with turbo stream format' do
    get translation_requests_url(format: :turbo_stream)
    assert_response :success
  end

  test 'should create translation request when authenticated' do
    sign_in @user

    assert_difference('TranslationRequest.count') do
      post translation_requests_url, params: {
        translation_request: {
          title: 'New Translation Request',
          author: 'New Author',
          source_url: 'https://example.com/new',
          notes: 'Some notes'
        }
      }
    end

    assert_redirected_to translation_requests_path
    assert_equal 'Запит на переклад успішно надіслано!', flash[:notice]
  end

  test 'should not create translation request with invalid params' do
    sign_in @user

    assert_no_difference('TranslationRequest.count') do
      post translation_requests_url, params: {
        translation_request: {
          title: '', # Invalid - empty title
          author: 'Author',
          source_url: 'https://example.com'
        }
      }
    end

    assert_response :unprocessable_content
  end

  test 'should update translation request when authenticated' do
    sign_in @user

    patch translation_request_url(@translation_request), params: {
      translation_request: {
        title: 'Updated Title',
        notes: 'Updated notes'
      }
    }

    assert_redirected_to translation_requests_path
    assert_equal 'Запит на переклад успішно оновлено!', flash[:notice]
    @translation_request.reload
    assert_equal 'Updated Title', @translation_request.title
  end

  test 'should update translation request with JSON format' do
    sign_in @user

    patch translation_request_url(@translation_request, format: :json), params: {
      translation_request: {
        title: 'Updated Title JSON'
      }
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_equal 'Запит успішно оновлено!', json_response['message']
  end

  test 'should handle update failure' do
    sign_in @user

    patch translation_request_url(@translation_request), params: {
      translation_request: {
        title: '' # Invalid - empty title
      }
    }

    assert_redirected_to translation_requests_path
    assert_equal 'Помилка при оновленні запиту.', flash[:alert]
  end

  test 'should assign translation request to scanlator' do
    sign_in @user

    patch assign_translation_request_path(@translation_request), params: {
      scanlator_id: @scanlator.id
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_equal 'Запит успішно призначено команді', json_response['message']
    assert_equal @scanlator.title, json_response['scanlator_title']

    @translation_request.reload
    assert_equal @scanlator.id, @translation_request.scanlator_id
  end

  test 'should not assign already assigned translation request' do
    sign_in @user
    @translation_request.update!(scanlator: @scanlator)

    patch assign_translation_request_path(@translation_request), params: {
      scanlator_id: @scanlator.id
    }

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert_equal 'Цей запит вже призначено іншій команді перекладачів', json_response['error']
  end

  test 'should unassign translation request' do
    sign_in @user
    @translation_request.update!(scanlator: @scanlator)

    delete unassign_translation_request_path(@translation_request)

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_equal 'Запит успішно відкликано від команди', json_response['message']

    @translation_request.reload
    assert_nil @translation_request.scanlator_id
  end

  test 'should destroy translation request when authenticated' do
    sign_in @user

    assert_difference('TranslationRequest.count', -1) do
      delete translation_request_url(@translation_request)
    end

    assert_redirected_to translation_requests_path
    assert_equal 'Запит на переклад успішно видалено!', flash[:notice]
  end

  test 'should destroy translation request with JSON format' do
    sign_in @user

    assert_difference('TranslationRequest.count', -1) do
      delete translation_request_url(@translation_request, format: :json)
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_equal 'Запит успішно видалено!', json_response['message']
  end

  test 'should require authentication for protected actions' do
    # Test create
    post translation_requests_url, params: {
      translation_request: { title: 'Test', author: 'Test', source_url: 'https://example.com' }
    }
    assert_redirected_to new_user_session_url

    # Test update
    patch translation_request_url(@translation_request), params: {
      translation_request: { title: 'Updated' }
    }
    assert_redirected_to new_user_session_url

    # Test assign
    patch assign_translation_request_path(@translation_request), params: { scanlator_id: @scanlator.id }
    assert_redirected_to new_user_session_url

    # Test unassign
    delete unassign_translation_request_path(@translation_request)
    assert_redirected_to new_user_session_url

    # Test destroy
    delete translation_request_url(@translation_request)
    assert_redirected_to new_user_session_url
  end

  test 'should handle non-existent translation request' do
    sign_in @user

    patch translation_request_url(99_999), params: {
      translation_request: { title: 'Updated' }
    }
    assert_response :not_found
  end

  test 'should handle assign with non-existent scanlator' do
    sign_in @user

    patch assign_translation_request_path(@translation_request), params: {
      scanlator_id: 99_999
    }
    assert_response :not_found
  end
end
