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

  test 'update chapter number refreshes fiction status when unique chapters reach total' do
    fiction = @chapter.fiction
    fiction.update!(status: :ongoing, total_chapters: 2)
    duplicate = chapters(:two)
    duplicate.update!(number: 1)

    assert_predicate fiction.reload, :ongoing?

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
    assert_predicate fiction.reload, :finished?
  end

  test 'should not update chapter with invalid data' do
    patch chapter_url(@chapter), params: { chapter: { content: '', number: '', title: '' } }

    assert_response :unprocessable_content
  end

  test 'guest is redirected to fiction when chapter is not yet public' do
    sign_out users(:user_one)
    @chapter.published_at = 1.day.from_now
    @chapter.save(validate: false)
    get chapter_url(@chapter)

    assert_redirected_to fiction_path(@chapter.fiction)
  ensure
    @chapter.published_at = nil
    @chapter.save(validate: false)
  end

  test 'signed in admin can view chapter before public time' do
    @chapter.published_at = 1.day.from_now
    @chapter.save(validate: false)
    get chapter_url(@chapter)

    assert_response :success
  ensure
    @chapter.published_at = nil
    @chapter.save(validate: false)
  end

  test 'signed in user without scanlator on chapter is redirected when not yet public' do
    sign_out users(:user_one)
    sign_in users(:user_two)
    @chapter.published_at = 1.day.from_now
    @chapter.save(validate: false)
    get chapter_url(@chapter)

    assert_redirected_to fiction_path(@chapter.fiction)
  ensure
    @chapter.published_at = nil
    @chapter.save(validate: false)
  end
end
