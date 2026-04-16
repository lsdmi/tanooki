# frozen_string_literal: true

require 'test_helper'

class TranslationRequestsControllerDestroyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @scanlator = scanlators(:one)
    # ScanlatorUser association already exists in fixtures
  end

  test 'should require authentication for protected actions' do
    tr = new_translation_request

    # Test create
    post translation_requests_url, params: {
      translation_request: { title: 'Test', author: 'Test', source_url: 'https://example.com' }
    }
    assert_redirected_to new_user_session_url

    # Test update
    patch translation_request_url(tr), params: {
      translation_request: { title: 'Updated' }
    }
    assert_redirected_to new_user_session_url

    # Test assign
    patch assign_translation_request_path(tr), params: { scanlator_id: @scanlator.id }
    assert_redirected_to new_user_session_url

    # Test unassign
    delete unassign_translation_request_path(tr)
    assert_redirected_to new_user_session_url

    # Test destroy
    delete translation_request_url(tr)
    assert_redirected_to new_user_session_url
  end

  test 'should handle non-existent translation request' do
    sign_in @user

    patch translation_request_url(99_999), params: {
      translation_request: { title: 'Updated' }
    }
    assert_response :not_found
  end

  test 'should destroy translation request when authenticated' do
    sign_in @user
    tr = new_translation_request

    assert_difference('TranslationRequest.count', -1) do
      delete translation_request_url(tr)
    end

    assert_redirected_to translation_requests_path
    assert_equal 'Запит на переклад успішно видалено!', flash[:notice]
  end

  test 'should destroy translation request with JSON format' do
    sign_in @user
    tr = new_translation_request

    assert_difference('TranslationRequest.count', -1) do
      delete translation_request_url(tr, format: :json)
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_equal 'Запит успішно видалено!', json_response['message']
  end

  private

  def new_translation_request
    TranslationRequest.create!(
      title: "Request #{SecureRandom.hex(4)}",
      author: 'Author',
      source_url: "https://example.com/req-#{SecureRandom.hex(4)}",
      notes: 'Notes for the translation request.',
      user: @user
    )
  end
end
