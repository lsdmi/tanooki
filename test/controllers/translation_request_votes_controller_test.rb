# frozen_string_literal: true

require 'test_helper'

class TranslationRequestVotesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @translation_request = translation_requests(:one)
    sign_in @user
  end

  test 'should create vote when user has not voted' do
    # First remove the existing vote so we can test creating a new one
    existing_vote = translation_request_votes(:one)
    existing_vote.destroy

    assert_difference('TranslationRequestVote.count') do
      post translation_request_translation_request_votes_url(@translation_request)
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['user_voted']
    assert_equal 2, json_response['votes_count'] # Should be 2 because user_two still has a vote
  end

  test 'should remove vote when user has already voted' do
    # Use existing fixture vote - user_one has already voted for translation_request :one
    assert_difference('TranslationRequestVote.count', -1) do
      post translation_request_translation_request_votes_url(@translation_request)
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['user_voted']
    assert_equal 1, json_response['votes_count'] # Should be 1 because user_two still has a vote
  end

  test 'should toggle vote correctly multiple times' do
    # First vote - should remove existing vote (user_one already voted for translation_request :one)
    post translation_request_translation_request_votes_url(@translation_request)
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['user_voted']
    assert_equal 1, json_response['votes_count'] # user_two still has a vote

    # Second vote - should create again
    post translation_request_translation_request_votes_url(@translation_request)
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['user_voted']
    assert_equal 2, json_response['votes_count'] # both users have votes

    # Third vote - should remove again
    post translation_request_translation_request_votes_url(@translation_request)
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['user_voted']
    assert_equal 1, json_response['votes_count'] # only user_two has a vote
  end

  test 'should require authentication' do
    sign_out @user

    post translation_request_translation_request_votes_url(@translation_request)
    assert_redirected_to new_user_session_url
  end

  test 'should handle non-existent translation request' do
    post translation_request_translation_request_votes_url(99_999)
    assert_response :not_found
  end

  test 'should return updated votes count from database' do
    # user_two already has a vote for translation_request :one in fixtures
    # user_one also has a vote, so removing user_one's vote should leave 1 vote

    post translation_request_translation_request_votes_url(@translation_request)

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['votes_count'] # Should be 1 after removing user_one's vote
    assert_equal false, json_response['user_voted']
  end
end
