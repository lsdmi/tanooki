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
    json_response = response.parsed_body

    assert_vote_create_response(json_response, votes_count: 2)
  end

  test 'should remove vote when user has already voted' do
    # Use existing fixture vote - user_one has already voted for translation_request :one
    assert_difference('TranslationRequestVote.count', -1) do
      post translation_request_translation_request_votes_url(@translation_request)
    end

    assert_response :success
    json_response = response.parsed_body

    assert_vote_remove_response(json_response, votes_count: 1)
  end

  test 'should toggle vote correctly multiple times' do
    post translation_request_translation_request_votes_url(@translation_request)

    assert_vote_remove_response(response.parsed_body, votes_count: 1)

    post translation_request_translation_request_votes_url(@translation_request)

    assert_vote_create_response(response.parsed_body, votes_count: 2)

    post translation_request_translation_request_votes_url(@translation_request)

    assert_vote_remove_response(response.parsed_body, votes_count: 1)
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

    json_response = response.parsed_body

    assert_vote_remove_response(json_response, votes_count: 1)
  end

  private

  def assert_vote_create_response(json_response, votes_count:)
    assert json_response['user_voted']
    assert_equal votes_count, json_response['votes_count']
  end

  def assert_vote_remove_response(json_response, votes_count:)
    assert_not json_response['user_voted']
    assert_equal votes_count, json_response['votes_count']
  end
end
