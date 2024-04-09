# frozen_string_literal: true

require 'test_helper'

class CommentsHelperTest < ActionView::TestCase
  include CommentsHelper

  test "no_comments_prompt should return correct prompt for chapters controller" do
    params[:controller] = 'chapters'
    assert_equal 'Наразі відгуки до цього розділу відсутні!', no_comments_prompt
  end

  test "no_comments_prompt should return correct prompt for fictions controller" do
    params[:controller] = 'fictions'
    assert_equal 'Наразі відгуки до цього твору відсутні!', no_comments_prompt
  end

  test "no_comments_prompt should return correct prompt for other controllers" do
    params[:controller] = 'other_controller'
    assert_equal 'Наразі відгуки до цієї звістки відсутні!', no_comments_prompt
  end

  test "comment_url returns correct URL for Chapter" do
    comment = comments(:comment_chapter)
    assert_equal chapter_path(comment.commentable), comment_url(comment)
  end

  test "comment_url returns correct URL for YoutubeVideo" do
    comment = comments(:comment_video)
    assert_equal youtube_video_path(comment.commentable), comment_url(comment)
  end

  test "comment_url returns correct URL for Fiction" do
    comment = comments(:comment_fiction)
    assert_equal fiction_path(comment.commentable), comment_url(comment)
  end

  test "comment_url returns correct URL for Publication" do
    comment = comments(:comment_publication)
    assert_equal tale_path(comment.commentable), comment_url(comment)
  end
end
