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
    [
      lambda {
        post translation_requests_url, params: {
          translation_request: {
            title: 'Test',
            author: 'Test',
            source_url: 'https://example.com'
          }
        }
      },
      -> { patch translation_request_url(tr), params: { translation_request: { title: 'Updated' } } },
      -> { patch assign_translation_request_path(tr), params: { scanlator_id: @scanlator.id } },
      -> { delete unassign_translation_request_path(tr) },
      -> { delete translation_request_url(tr) }
    ].each do |request|
      request.call

      assert_redirected_to new_user_session_url
    end
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

  test 'should forbid destroying another users translation request' do
    sign_in users(:user_two)
    tr = new_translation_request

    assert_no_difference('TranslationRequest.count') do
      delete translation_request_url(tr)
    end

    assert_response :forbidden
  end

  test 'should destroy translation request with JSON format' do
    sign_in @user
    tr = new_translation_request

    assert_difference('TranslationRequest.count', -1) do
      delete translation_request_url(tr, format: :json)
    end

    assert_response :success
    verify_translation_request_json_destroy_success
  end

  private

  def verify_translation_request_json_destroy_success
    json_response = response.parsed_body

    assert json_response['success']
    assert_equal 'Запит успішно видалено!', json_response['message']
  end

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
