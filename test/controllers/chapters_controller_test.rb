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

  test 'show uses immersive reader layout without site navbar or footer' do
    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, 'Налаштування читання'
    assert_includes response.body, 'baka.in.ua™'
    assert_not_includes response.body, 'Популярні теґи'
    assert_not_includes response.body, 'id="site-logo"'
    assert_includes response.body, 'reader-comments hidden'
    assert_includes response.body, 'data-comments-toggle-target="contentSection" class="w-full lg:w-full"'
    assert_not_includes response.body, 'reader-ad-slot'
  end

  test 'guest sees login to download epub banner when epub is available' do
    sign_out users(:user_one)
    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, 'reader-epub-banner'
    assert_includes response.body, I18n.t('chapters.reader_epub_banner.title')
    assert_includes response.body, I18n.t('chapters.reader_epub_banner.login_description')
    assert_includes response.body, new_user_session_path
  end

  test 'signed in user does not see login epub banner' do
    get chapter_url(@chapter)

    assert_response :success
    assert_not_includes response.body, 'reader-epub-banner'
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
