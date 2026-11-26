# frozen_string_literal: true

require 'test_helper'

class CommentReviewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
              'Чекаю продовження й дякую команді за роботу.'

  setup do
    ActionController::Base.cache_store.clear
    @fiction = fictions(:two)
    @reader = users('user_101')
    @comment = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
    FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
    sign_in @reader
  end

  test 'the author marks a comment as a review and gets the thread comment back' do
    assert_difference('FictionReview.count') { post comment_review_path(@comment, format: :turbo_stream) }

    assert_response :success
    assert_includes response.body, %(target="comment_#{@comment.id}")
  end

  test 'a mark redraws the reviews filter with its count and the order the reader is looking at' do
    post comment_review_path(@comment, format: :turbo_stream, order: 'asc', filter: 'reviews')

    assert_includes response.body, %(target="fiction_review_filter")
    assert_includes response.body, 'Відгуки (1)'
    assert_includes response.body, 'filter=reviews&amp;order=asc'
  end

  test 'the marked comment keeps the list state on its unmark link' do
    post comment_review_path(@comment, format: :turbo_stream, order: 'asc', filter: 'reviews')

    assert_includes response.body, %(href="/comments/#{@comment.id}/review?filter=reviews&amp;order=asc")
  end

  test 'a mark without list state redraws the filter with the default order' do
    post comment_review_path(@comment, format: :turbo_stream)

    assert_includes response.body, %(target="fiction_review_filter")
    assert_includes response.body, 'order=desc'
  end

  test 'the author takes the mark off and the comment stays' do
    post comment_review_path(@comment, format: :turbo_stream)

    assert_difference('FictionReview.count', -1) { delete comment_review_path(@comment, format: :turbo_stream) }

    assert_response :success
    assert_equal LONG_TEXT, @comment.reload.content
  end

  test 'a guest is sent to login from a turbo stream request too' do
    sign_out @reader

    assert_no_difference('FictionReview.count') { post comment_review_path(@comment, format: :turbo_stream) }

    assert_redirected_to new_user_session_url
  end

  test 'a stranger gets 403 even with their own rating' do
    stranger = users(:user_two)
    FictionRating.create!(user: stranger, fiction: @fiction, rating: 5)
    sign_in stranger

    assert_no_difference('FictionReview.count') { post comment_review_path(@comment, format: :turbo_stream) }

    assert_response :forbidden
  end

  test 'a team member marks their own fiction comment as a review' do
    team_member = users(:user_two)
    ScanlatorUser.create!(scanlator: scanlators(:one), user: team_member)
    own_comment = Comment.create!(user: team_member, commentable: @fiction, content: LONG_TEXT)
    FictionRating.create!(user: team_member, fiction: @fiction, rating: 5)
    sign_in team_member

    assert_difference('FictionReview.count') { post comment_review_path(own_comment, format: :turbo_stream) }

    assert_response :success
  end

  test 'a stranger cannot take someone else’s mark off' do
    post comment_review_path(@comment, format: :turbo_stream)
    sign_in users(:user_two)

    assert_no_difference('FictionReview.count') { delete comment_review_path(@comment, format: :turbo_stream) }

    assert_response :forbidden
  end

  test 'an admin takes someone else’s mark off' do
    post comment_review_path(@comment, format: :turbo_stream)
    sign_in users(:user_one)

    assert_difference('FictionReview.count', -1) { delete comment_review_path(@comment, format: :turbo_stream) }

    assert_response :success
    assert_equal LONG_TEXT, @comment.reload.content
  end
end
