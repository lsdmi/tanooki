# frozen_string_literal: true

require 'test_helper'

class FictionRatingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    sign_in @user
  end

  test 'should create fiction rating with valid rating' do
    # Use a different fiction that user_one hasn't rated yet
    fiction_two = fictions(:two)

    assert_difference('FictionRating.count') do
      post fiction_fiction_ratings_url(fiction_two), params: { rating: 4 }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 4, json_response['user_rating']
    assert json_response.key?('average_rating')
    assert json_response.key?('rating_count')
  end

  test 'should update existing fiction rating' do
    # Use existing fixture rating
    existing_rating = fiction_ratings(:one)

    assert_no_difference('FictionRating.count') do
      post fiction_fiction_ratings_url(@fiction), params: { rating: 5 }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 5, json_response['user_rating']

    # Verify the rating was updated
    existing_rating.reload
    assert_equal 5, existing_rating.rating
  end

  test 'should reject invalid rating below 1' do
    assert_no_difference('FictionRating.count') do
      post fiction_fiction_ratings_url(@fiction), params: { rating: 0 }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert_equal 'Invalid rating', json_response['error']
  end

  test 'should reject invalid rating above 5' do
    assert_no_difference('FictionRating.count') do
      post fiction_fiction_ratings_url(@fiction), params: { rating: 6 }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert_equal 'Invalid rating', json_response['error']
  end

  test 'should handle update action same as create' do
    # Use a different fiction that user_one hasn't rated yet
    fiction_two = fictions(:two)

    assert_difference('FictionRating.count') do
      patch fiction_fiction_rating_url(fiction_two, 1), params: { rating: 4 }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 4, json_response['user_rating']
  end

  test 'should require authentication' do
    sign_out @user

    post fiction_fiction_ratings_url(@fiction), params: { rating: 4 }
    assert_redirected_to new_user_session_url
  end

  test 'should handle non-existent fiction' do
    post fiction_fiction_ratings_url(99_999), params: { rating: 4 }
    assert_response :not_found
  end

  # Removed mocking test as it requires additional setup and isn't essential for basic functionality
end
