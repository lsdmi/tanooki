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
          title: @chapter.title
        }
      }
    end

    assert_redirected_to reading_path(@chapter.fiction)
    assert_equal users(:user_one).id, Chapter.order(:id).last.user_id
  end

  test 'should not create chapter with invalid data' do
    assert_no_difference('Chapter.count') do
      post chapters_url, params: { chapter: { content: '', fiction_id: '', number: '', title: '' } }
    end

    assert_redirected_to root_path
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

  test 'should return to the originating chapter list page after update' do
    patch chapter_url(@chapter, page: 3), params: {
      chapter: {
        content: @chapter.content,
        fiction_id: @chapter.fiction_id,
        number: @chapter.number,
        scanlator_ids: [1],
        title: @chapter.title
      }
    }

    assert_redirected_to reading_path(@chapter.fiction, page: 3)
  end

  test 'update chapter number does not mark the listing finished from chapter count' do
    fiction = @chapter.fiction
    fiction.update!(expected_chapters: 2, completed_at: nil)
    duplicate = chapters(:two)
    duplicate.update!(number: 1)

    patch chapter_url(duplicate), params: {
      chapter: {
        content: duplicate.content,
        fiction_id: fiction.id,
        number: 2,
        scanlator_ids: [1],
        title: duplicate.title
      }
    }

    assert_redirected_to reading_path(fiction)
    fiction.reload

    assert_nil fiction.completed_at
    assert_not_equal :finished, fiction.listing_state
  end

  test 'should not update chapter with invalid data' do
    patch chapter_url(@chapter), params: { chapter: { content: '', number: '', title: '' } }

    assert_response :unprocessable_content
  end
end
