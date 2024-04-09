# frozen_string_literal: true

require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    @publication = publications(:tale_approved_one)
    @comment = comments(:comment_one)
    @user = users(:user_one)
    login_as(@user, scope: :user)
  end

  test 'should create comment' do
    assert_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: { content: 'New comment', commentable_id: @publication.id, commentable_type: Tale, user_id: @user.id }
      }
    end
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

  test "should get index" do
    get comments_url
    assert_response :success
    assert_not_nil assigns(:pagy)
    assert_not_nil assigns(:comments)
  end
end
