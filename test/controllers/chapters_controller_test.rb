# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @chapter = chapters(:one)
  end

  test 'should get show' do
    get chapter_url(@chapter)
    assert_response :success
  end

  test 'should get comments' do
    @chapter.comments << comments(:comment_one)
    get chapter_url(@chapter)
    assert_equal @chapter.comments, assigns(:comments)
  end

  test 'should get comments page' do
    @chapter.comments << comments(:comment_one)
    get comments_chapter_url(@chapter)
    assert_response :success
    assert_equal @chapter.comments.parents.order(created_at: :desc), assigns(:comments)
    assert_equal @chapter, assigns(:commentable)
  end

  test 'should get next chapter' do
    get chapter_path(@chapter)
    assert_equal chapters(:two), assigns(:next_chapter)
  end

  test 'should get new' do
    get new_chapter_url(fiction: 'one')
    assert_response :success
  end

  test 'should create chapter' do
    assert_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: {
          content: @chapter.content,
          fiction_id: @chapter.fiction_id,
          number: @chapter.number,
          scanlator_ids: [1],
          title: @chapter.title,
          user_id: @chapter.user_id
        }
      }
    end

    assert_redirected_to reading_path(@chapter.fiction)
  end

  test 'should not create chapter with invalid data' do
    assert_no_difference('Chapter.count') do
      post chapters_url, params: { chapter: { content: '', fiction_id: '', number: '', title: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'should get edit' do
    get chapter_url(@chapter)
    assert_response :success
  end

  test 'should update chapter' do
    patch chapter_url(@chapter), params: {
      chapter: {
        content: @chapter.content,
        fiction_id: @chapter.fiction_id,
        number: @chapter.number,
        scanlator_ids: [1],
        title: @chapter.title
      }
    }
    assert_redirected_to reading_path(@chapter.fiction)
  end

  test 'should not update chapter with invalid data' do
    patch chapter_url(@chapter), params: { chapter: { content: '', number: '', title: '' } }
    assert_response :unprocessable_content
  end

  test 'should create chapter with publish_at' do
    publish_time = 3.days.from_now
    assert_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: {
          content: @chapter.content,
          fiction_id: @chapter.fiction_id,
          number: 99,
          scanlator_ids: [1],
          title: 'Scheduled chapter',
          user_id: @chapter.user_id,
          publish_at: publish_time.strftime('%Y-%m-%dT%H:%M')
        }
      }
    end

    created_chapter = Chapter.last
    assert created_chapter.scheduled?
    assert_not_nil created_chapter.publish_at
  end

  test 'should redirect reader from scheduled chapter' do
    sign_in users(:user_two)
    scheduled_chapter = chapters(:scheduled)
    get chapter_url(scheduled_chapter)
    assert_redirected_to fiction_path(scheduled_chapter.fiction)
  end
end
