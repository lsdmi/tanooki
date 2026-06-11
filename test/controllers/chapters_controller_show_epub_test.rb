# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerShowEpubTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
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
    sign_in users(:user_one)
    get chapter_url(@chapter)

    assert_response :success
    assert_not_includes response.body, 'reader-epub-banner'
  end
end
