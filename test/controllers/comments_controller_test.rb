# frozen_string_literal: true

require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @publication = publications(:tale_approved_one)
    @comment = comments(:comment_one)
    @user = users(:user_one)
    sign_in @user
    ActionController::Base.cache_store.clear
  end

  test 'should create comment' do
    assert_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: { content: 'New comment', commentable_id: @publication.id, commentable_type: Tale }
      }
    end

    assert_equal @user, Comment.order(:id).last.user
  end

  test 'rate limits comment creation per ip' do
    20.times do |index|
      post comments_url(format: :turbo),
           params: {
             comment: {
               content: "Comment #{index}",
               commentable_id: @publication.id,
               commentable_type: 'Tale'
             }
           },
           env: { 'REMOTE_ADDR' => '203.0.113.12' }
    end

    post comments_url(format: :turbo),
         params: {
           comment: {
             content: 'One too many',
             commentable_id: @publication.id,
             commentable_type: 'Tale'
           }
         },
         env: { 'REMOTE_ADDR' => '203.0.113.12' }

    assert_response :too_many_requests
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
end
