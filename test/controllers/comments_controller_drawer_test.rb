# frozen_string_literal: true

require 'test_helper'

class CommentsControllerDrawerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'creating chapter comment updates drawer count stream' do
    chapter = chapters(:two)
    chapter.update!(comments_count: 0)

    post comments_url(format: :turbo_stream),
         params: {
           comment: {
             content: 'New chapter comment',
             commentable_id: chapter.id,
             commentable_type: 'Chapter'
           }
         },
         headers: { 'Referer' => chapter_url(chapter) }

    assert_response :success
    assert_includes response.body, 'reader-comments-count'
    assert_includes response.body, '1 коментар до цього розділу'
  end

  test 'creating chapter comment increments comments count' do
    chapter = chapters(:two)
    chapter.update!(comments_count: 0)

    post comments_url(format: :turbo_stream),
         params: {
           comment: {
             content: 'New chapter comment',
             commentable_id: chapter.id,
             commentable_type: 'Chapter'
           }
         },
         headers: { 'Referer' => chapter_url(chapter) }

    assert_equal 1, chapter.reload.comments_count
  end

  test 'destroying chapter comment updates drawer count stream' do
    chapter_comment = comments(:comment_chapter)
    chapter = chapters(:two)
    chapter.update!(comments_count: 1)

    delete comment_url(chapter_comment, format: :turbo_stream),
           headers: { 'Referer' => chapter_url(chapter) }

    assert_response :success
    assert_includes response.body, 'reader-comments-count'
    assert_includes response.body, '0 коментарів до цього розділу'
  end

  test 'destroying chapter comment decrements comments count' do
    chapter_comment = comments(:comment_chapter)
    chapter = chapters(:two)
    chapter.update!(comments_count: 1)

    delete comment_url(chapter_comment, format: :turbo_stream),
           headers: { 'Referer' => chapter_url(chapter) }

    assert_equal 0, chapter.reload.comments_count
  end

  test 'chapter comment edit from reader uses drawer form field' do
    chapter_comment = comments(:comment_chapter)
    chapter = chapters(:two)

    get edit_comment_url(chapter_comment, format: :turbo_stream),
        headers: { 'Turbo-Frame' => 'comment-content', 'Referer' => chapter_url(chapter) }

    assert_response :success
    assert_includes response.body, 'reader-comments-drawer__input'
    assert_includes response.body, "comment-field-#{chapter_comment.id}"
  end

  test 'chapter comment cancel edit restores drawer content frame' do
    chapter_comment = comments(:comment_chapter)
    chapter = chapters(:two)

    get cancel_edit_comment_url(chapter_comment, format: :turbo_stream),
        headers: { 'Referer' => chapter_url(chapter) }

    assert_response :success
    assert_includes response.body, 'reader-comments-drawer__content'
    assert_includes response.body, 'turbo-stream action="replace"'
  end

  test 'chapter comment cancel edit targets comment content frame' do
    chapter_comment = comments(:comment_chapter)
    chapter = chapters(:two)

    get cancel_edit_comment_url(chapter_comment, format: :turbo_stream),
        headers: { 'Referer' => chapter_url(chapter) }

    assert_includes response.body, "comment-content-#{chapter_comment.id}"
  end
end
