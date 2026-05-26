# frozen_string_literal: true

require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @publication = publications(:tale_approved_one)
    @comment = comments(:comment_one)
    @user = users(:user_one)
    sign_in @user
  end

  test 'should create comment' do
    assert_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: { content: 'New comment', commentable_id: @publication.id, commentable_type: Tale }
      }
    end

    assert_equal @user, Comment.order(:id).last.user
  end

  test 'should ignore spoofed user id when creating comment' do
    assert_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: {
          content: 'New comment',
          commentable_id: @publication.id,
          commentable_type: Tale,
          user_id: users(:user_two).id
        }
      }
    end

    assert_equal @user, Comment.order(:id).last.user
  end

  test 'should destroy comment' do
    assert_difference('Comment.count', -1) do
      delete comment_url(@comment, format: :turbo)
    end
  end

  test 'should get edit' do
    get edit_comment_url(@comment, format: :turbo)

    assert_response :success
  end

  test 'should cancel edit' do
    get cancel_edit_comment_url(@comment, format: :turbo_stream)

    assert_template 'complete_update'
  end

  test 'should cancel reply' do
    get cancel_reply_comment_url(@comment, format: :turbo)

    assert_response :success
  end

  test 'should update comment' do
    patch comment_url(@comment, format: :turbo_stream), params: { comment: { content: 'Updated comment' } }

    assert_template 'complete_update'
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
