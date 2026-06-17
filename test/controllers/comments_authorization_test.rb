# frozen_string_literal: true

require 'test_helper'

class CommentsAuthorizationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @publication = publications(:tale_approved_one)
    @comment = comments(:comment_one)
    @user = users(:user_one)
    sign_in @user
  end

  test 'guest should not create comment' do
    sign_out @user

    assert_no_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: { content: 'New comment', commentable_id: @publication.id, commentable_type: Tale }
      }
    end

    assert_response :unauthorized
  end

  test 'rejects non-whitelisted commentable_type' do
    assert_no_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: { content: 'Hack comment', commentable_id: @publication.id, commentable_type: 'User' }
      }
    end

    assert_response :unprocessable_content
  end

  test 'invalid commentable_id does not create comment or change counter cache' do
    before_count = @publication.comments_count

    assert_no_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: { content: 'Orphan comment', commentable_id: 999_999, commentable_type: 'Publication' }
      }
    end

    assert_response :unprocessable_content
    assert_equal before_count, @publication.reload.comments_count
  end

  test 'guest should not edit comment' do
    sign_out @user

    get edit_comment_url(@comment, format: :turbo)

    assert_response :unauthorized
  end

  test 'non-owner should not edit comment' do
    sign_out @user
    sign_in users(:user_two)

    get edit_comment_url(@comment, format: :turbo)

    assert_response :forbidden
  end

  test 'non-owner should not update comment' do
    sign_out @user
    sign_in users(:user_two)
    original_content = @comment.content

    patch comment_url(@comment, format: :turbo_stream), params: { comment: { content: 'Updated by another user' } }

    assert_response :forbidden
    assert_equal original_content, @comment.reload.content
  end

  test 'non-owner should not destroy comment' do
    sign_out @user
    sign_in users(:user_two)

    assert_no_difference('Comment.count') do
      delete comment_url(@comment, format: :turbo)
    end

    assert_response :forbidden
  end
end
