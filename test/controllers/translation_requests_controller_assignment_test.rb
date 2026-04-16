# frozen_string_literal: true

require 'test_helper'

class TranslationRequestsControllerAssignmentTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @scanlator = scanlators(:one)
    @translation_request = translation_requests(:one)
    # ScanlatorUser association already exists in fixtures
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

  test 'should handle assign with non-existent scanlator' do
    sign_in @user

    patch assign_translation_request_path(@translation_request), params: {
      scanlator_id: 99_999
    }
    assert_response :not_found
  end
end
