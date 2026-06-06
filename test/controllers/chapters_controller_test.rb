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

  test 'show blurs chapter text behind adult content gate until consent' do
    @chapter.fiction.update!(adult_content: true)

    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, I18n.t('fictions.adult_content_disclaimer.reader_title')
    assert_includes response.body, 'adult-content-gate--locked'
    assert_includes response.body, 'data-adult-content-gate-content'
    assert_includes response.body, I18n.t('fictions.adult_content_disclaimer.dismiss')
  end

  test 'show uses immersive reader layout without site navbar or footer' do
    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, 'Налаштування читання'
    assert_includes response.body, 'baka.in.ua™'
    assert_not_includes response.body, 'Популярні теґи'
    assert_not_includes response.body, 'id="site-logo"'
    assert_includes response.body, 'reader-comments-drawer'
    assert_includes response.body, 'data-comments-drawer-target="panel"'
    assert_includes response.body, 'reader-chapter-drawer'
    assert_includes response.body, 'chapter-drawer-search'
    assert_includes response.body, I18n.t('chapters.reader_chapter_drawer.search_placeholder')
    assert_includes response.body, I18n.t('chapters.reader_chapter_drawer.progress_current')
    assert_includes response.body, 'reader-chapter-list-panel'
    assert_includes response.body, 'data-chapter-drawer-target="panel"'
    assert_includes response.body, I18n.t('chapters.reader_comments_drawer.title')
    assert_not_includes response.body, 'reader-ad-slot'
    assert_includes response.body, 'reader-bottom-grid'
    assert_includes response.body, 'reader-anchor-card'
    assert_includes response.body, I18n.t('chapters.reader_anchor_card.home')
  end

  test 'show renders translator support card when scanlator has bank url' do
    @chapter.fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')

    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, 'reader-support-card'
    assert_includes response.body, I18n.t('chapters.reader_support_card.title')
    assert_includes response.body, I18n.t('chapters.reader_support_card.support')
    assert_includes response.body, 'mascot.svg'
    assert_includes response.body, 'mascot-dark.svg'
  end

  test 'guest sees login to download epub banner when epub is available' do
    sign_out users(:user_one)
    get chapter_url(@chapter)

    assert_response :success
    assert_select 'section.reader-epub-banner', count: 1
    assert_includes response.body, 'reader-epub-banner-title'
    assert_not_includes response.body, 'reader-epub-banner-title-bottom'
    assert_not_includes response.body, 'reader-epub-banner-slot'
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
