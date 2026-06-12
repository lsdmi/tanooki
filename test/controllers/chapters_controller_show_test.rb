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

  test 'reader settings panel is full screen on mobile and side drawer from sm up' do
    get chapter_url(@chapter)

    assert_select '#reader-settings-panel.reader-settings__panel.fixed.inset-0.sm\\:inset-y-0.sm\\:left-auto.sm\\:right-0.sm\\:max-w-sm', count: 1
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

  test 'guest sees login cta in comments drawer when chapter has comments' do
    @chapter.comments << comments(:comment_one)
    sign_out users(:user_one)

    get chapter_url(@chapter)

    assert_includes response.body, I18n.t('chapters.reader_comments_drawer.login_prompt')
    assert_includes response.body, I18n.t('chapters.reader_comments_drawer.login_to_comment')
    assert_not_includes response.body, Comments::Presentation.empty_state_for('chapters')
    assert_includes response.body, new_user_session_path
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

  test 'team member who did not author chapter sees edit link in reader settings' do
    teammate = users(:user_two)
    ScanlatorUser.create!(user: teammate, scanlator: scanlators(:one))
    sign_in teammate

    get chapter_url(@chapter)

    assert_response :success
    assert_includes response.body, I18n.t('chapters.reader_settings.edit_chapter')
    assert_includes response.body, edit_chapter_path(@chapter)
  end

  test 'user outside chapter team does not see edit link in reader settings' do
    sign_in users(:user_two)

    get chapter_url(@chapter)

    assert_response :success
    assert_not_includes response.body, I18n.t('chapters.reader_settings.edit_chapter')
  end
end
