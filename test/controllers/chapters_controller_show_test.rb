# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerShowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @chapter = chapters(:one)
  end

  test 'show blurs chapter text behind adult content gate until consent' do
    @chapter.fiction.update!(adult_content: true)

    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, I18n.t('fictions.adult_content_disclaimer.reader_title')
    assert_includes response.body, 'adult-content-gate--locked'
  end

  test 'show adult gate includes dismiss control and gated content wrapper' do
    @chapter.fiction.update!(adult_content: true)

    get chapter_url(@chapter)

    assert_includes response.body, 'data-adult-content-gate-content'
    assert_includes response.body, I18n.t('fictions.adult_content_disclaimer.dismiss')
  end

  test 'show uses immersive reader chrome' do
    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, 'Налаштування читання'
    assert_includes response.body, 'baka.in.ua™'
  end

  test 'show hides site navigation chrome' do
    get chapter_url(@chapter)

    assert_not_includes response.body, 'Популярні теґи'
    assert_not_includes response.body, 'id="site-logo"'
    assert_not_includes response.body, 'reader-ad-slot'
  end

  test 'show renders comments drawer' do
    get chapter_url(@chapter)

    assert_includes response.body, 'reader-comments-drawer'
    assert_includes response.body, 'data-comments-drawer-target="panel"'
    assert_includes response.body, I18n.t('chapters.reader_comments_drawer.title')
  end

  test 'show renders chapter drawer' do
    get chapter_url(@chapter)

    assert_includes response.body, 'reader-chapter-drawer'
    assert_includes response.body, 'chapter-drawer-search'
    assert_includes response.body, I18n.t('chapters.reader_chapter_drawer.search_placeholder')
  end

  test 'show renders chapter drawer progress and list panel' do
    get chapter_url(@chapter)

    assert_includes response.body, I18n.t('chapters.reader_chapter_drawer.progress_current')
    assert_includes response.body, 'reader-chapter-list-panel'
    assert_includes response.body, 'data-chapter-drawer-target="panel"'
  end

  test 'show renders reader bottom cards' do
    get chapter_url(@chapter)

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
  end

  test 'show support card includes support link and mascot assets' do
    @chapter.fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')

    get chapter_url(@chapter)

    assert_includes response.body, I18n.t('chapters.reader_support_card.support')
    assert_select 'img.reader-support-card__mascot.dark\\:hidden[src*="mascot"]', count: 1
    assert_select 'img.reader-support-card__mascot.hidden[src*="mascot-dark"]', count: 1
  end

  test 'guest sees login to download epub banner when epub is available' do
    sign_out users(:user_one)
    get chapter_url(@chapter)

    assert_response :success
    assert_select 'section.reader-epub-banner', count: 1
    assert_includes response.body, 'reader-epub-banner-title'
  end

  test 'guest epub banner shows login copy and session link' do
    sign_out users(:user_one)
    get chapter_url(@chapter)

    assert_not_includes response.body, 'reader-epub-banner-title-bottom'
    assert_includes response.body, I18n.t('chapters.reader_epub_banner.login_description')
    assert_includes response.body, new_user_session_path
  end

  test 'signed in user does not see login epub banner' do
    get chapter_url(@chapter)

    assert_response :success
    assert_not_includes response.body, 'reader-epub-banner'
  end
end
